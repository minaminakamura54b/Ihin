class AiAssessmentService
  MAX_IMAGES   = 5
  API_MAX_BYTES = 3_500_000  # base64後に5MB以内に収まるよう余裕を持たせる

  ImageProxy = Struct.new(:data, :content_type) do
    def attached? = data.present?
    def download = data
  end

  GuestImagesProxy = Struct.new(:proxies) do
    include Enumerable
    def each(&block) = proxies.each(&block)
    def attached? = proxies.any?(&:attached?)
  end

  GuestItem = Struct.new(:images_proxies, :name, :memo) do
    def images = GuestImagesProxy.new(images_proxies || [])
    def assessed? = false
  end

  def self.assess_upload(images:, name: nil, memo: nil)
    proxies = images.map { |img| ImageProxy.new(img[:data], img[:content_type]) }
    new(GuestItem.new(proxies, name, memo)).assess
  end

  def initialize(item)
    @item = item
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  end

  def assess
    images_data = fetch_images_data
    processed_imgs = images_data.filter_map { |data| image_for_api(data) }.first(MAX_IMAGES)
    messages = build_messages(processed_imgs)

    response = @client.messages.create(
      model: "claude-opus-4-5",
      max_tokens: 1024,
      messages: messages
    )

    result = parse_response(response.content.first.text)
    result[:processed_images] = processed_imgs if result[:success]
    result
  rescue => e
    { success: false, error: e.message }
  end

  private

  def fetch_images_data
    return [] unless @item.images.attached?
    @item.images.map { |img| img.download rescue nil }.compact
  rescue
    []
  end

  def image_for_api(image_data)
    return nil unless image_data

    img = MiniMagick::Image.read(image_data)
    img.format "jpeg"
    img.resize "1600x1600>"
    img.quality 82

    blob = img.to_blob

    # それでも大きい場合はさらに圧縮
    if blob.bytesize > API_MAX_BYTES
      img.resize "1000x1000>"
      img.quality 72
      blob = img.to_blob
    end

    { data: blob, content_type: "image/jpeg" }
  rescue
    nil
  end

  def build_messages(processed_imgs)
    content = []

    processed_imgs.each do |img|
      content << {
        type: "image",
        source: {
          type: "base64",
          media_type: img[:content_type],
          data: Base64.strict_encode64(img[:data])
        }
      }
    end

    content << {
      type: "text",
      text: assessment_prompt(processed_imgs.size)
    }

    [ { role: "user", content: content } ]
  end

  def assessment_prompt(image_count = 0)
    subject = case image_count
              when 0 then "遺品（#{@item.name}）"
              when 1 then "この画像に写っている遺品"
              else "#{image_count}枚の画像に写っている遺品"
              end

    <<~PROMPT
      あなたは遺品査定の専門家です。#{subject}について、以下の形式で査定結果を日本語でお答えください。

      遺族が精神的につらい時期にあることを念頭に置き、温かく丁寧な言葉で回答してください。

      必ず以下のJSON形式で回答してください（JSON以外のテキストは含めないでください）：
      {
        "item_name": "品物の名前",
        "description": "品物の説明（2〜3文）",
        "estimated_price_min": 最低価格（円、整数）,
        "estimated_price_max": 最高価格（円、整数）,
        "estimated_price": 中間価格（円、整数）,
        "suggested_action": "sell" または "keep" または "dispose",
        "action_reason": "その理由（1〜2文、温かい言葉で）",
        "market_trend": "相場の傾向（1文）",
        "care_notes": "保管・取り扱い上の注意（任意）",
        "full_assessment": "総合的な査定コメント（3〜5文、遺族への配慮を含む）"
      }

      suggested_actionの基準：
      - "sell": 買取市場で価値があり、遺族の生活支援になる場合
      - "keep": 思い出として価値が高く、家族が保管すべき場合
      - "dispose": 状態が悪く価値がなく、処分が適切な場合

      #{@item.memo.present? ? "遺族からのメモ：#{@item.memo}" : ""}
    PROMPT
  end

  def parse_response(text)
    json_text = text.match(/\{.*\}/m)&.to_s
    return { success: false, error: "AI応答の解析に失敗しました" } unless json_text

    data = JSON.parse(json_text)

    {
      success: true,
      item_name: data["item_name"],
      ai_result: data["full_assessment"],
      estimated_price: data["estimated_price"],
      suggested_action: data["suggested_action"],
      raw_data: data
    }
  rescue JSON::ParserError
    { success: false, error: "JSONの解析に失敗しました" }
  end
end
