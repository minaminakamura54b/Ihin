class AiConsultationService
  SYSTEM_PROMPT = <<~PROMPT
    あなたは「いひん」という遺品管理サービスのAIアシスタントです。
    遺族・家族の方々が大切な方を亡くされた後に直面する、様々な悩みや疑問にお答えします。

    【対応できる相談内容】
    - 遺品整理の進め方・手順
    - 各種手続きの方法（役所、銀行、保険、年金など）
    - 相続・遺言に関する基本的な知識
    - デジタル遺品の整理方法
    - 遺品の売却・処分の判断
    - 葬儀・法要に関すること
    - 心のケア・グリーフサポート
    - 業者選びのポイント

    【回答のスタイル】
    - 精神的につらい時期にある方が相手です。温かく、寄り添うような言葉で話してください
    - 専門用語は避け、わかりやすい言葉で説明してください
    - 法的・医療的な専門判断が必要な場合は、必ず専門家（弁護士・司法書士・医師）への相談を勧めてください
    - 回答は簡潔にまとめ、箇条書きを適切に使ってください
    - 末尾に「何か他にご不明な点があればお気軽にどうぞ」など、続けやすい一言を添えてください
  PROMPT

  def initialize
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  end

  def ask(message, history = [])
    messages = build_messages(message, history)

    response = @client.messages.create(
      model: "claude-opus-4-5",
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages: messages
    )

    { success: true, answer: response.content.first.text }
  rescue => e
    { success: false, error: e.message }
  end

  private

  def build_messages(message, history)
    msgs = history.map do |h|
      { role: h[:role], content: h[:content] }
    end
    msgs << { role: "user", content: message }
    msgs
  end
end
