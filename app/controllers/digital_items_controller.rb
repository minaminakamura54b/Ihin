class DigitalItemsController < ApplicationController
  before_action :set_digital_item, only: [ :update, :destroy, :toggle_status ]

  def index
    @digital_items = current_user.digital_items.by_priority
    @by_category   = @digital_items.group_by(&:category)
    @total         = @digital_items.count
    @completed     = @digital_items.completed.count
    @active_tab    = params[:category].presence || "sns"
  end

  def create
    @digital_item = current_user.digital_items.new(digital_item_params)
    if @digital_item.save
      respond_to do |format|
        format.html { redirect_to digital_items_path, notice: "追加しました" }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to digital_items_path, alert: "追加できませんでした" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("digital_item_form", partial: "form") }
      end
    end
  end

  def destroy
    @digital_item.destroy
    respond_to do |format|
      format.html { redirect_to digital_items_path, notice: "削除しました" }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("digital_item_#{@digital_item.id}") }
    end
  end

  # ステータスをサイクル更新する（未対応→対応中→完了→未対応）
  def toggle_status
    next_status = { "unchecked" => :in_progress, "in_progress" => :completed, "completed" => :unchecked }
    @digital_item.update!(status: next_status[@digital_item.status])

    @total     = current_user.digital_items.count
    @completed = current_user.digital_items.completed.count

    respond_to do |format|
      format.html { redirect_to digital_items_path }
      format.turbo_stream
    end
  end

  # AIにリストを自動生成してもらう
  def ai_generate
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

    prompt = <<~PROMPT
      故人が使っていたと思われるデジタルサービスの整理チェックリストを作成してください。
      よく使われるSNS・サブスク・デバイスをカテゴリ別にJSON形式でリストアップしてください。

      以下のJSON形式で返してください（JSON以外のテキストは含めないでください）：
      {
        "items": [
          {"category": "sns", "service_name": "LINE", "priority": 1},
          {"category": "sns", "service_name": "Instagram", "priority": 2},
          {"category": "subscription", "service_name": "Netflix", "priority": 1},
          {"category": "device", "service_name": "iPhone", "priority": 1}
        ]
      }

      categoryは "sns", "subscription", "device", "other" のいずれか。
      priorityは 1（高）〜 3（低）。
      日本でよく使われるサービスを中心に、SNS5件・サブスク6件・デバイス4件・その他2件程度。
    PROMPT

    response = client.messages.create(
      model:      "claude-sonnet-4-5",
      max_tokens: 1024,
      messages:   [ { role: "user", content: prompt } ]
    )

    json_text = response.content.first.text.match(/\{.*\}/m)&.to_s
    data      = JSON.parse(json_text)

    created = 0
    data["items"].each do |item|
      next unless DigitalItem.categories.key?(item["category"].to_s)
      next if current_user.digital_items.exists?(service_name: item["service_name"])

      current_user.digital_items.create!(
        category:     item["category"],
        service_name: item["service_name"],
        priority:     item["priority"].to_i.clamp(1, 3),
        status:       :unchecked
      )
      created += 1
    end

    redirect_to digital_items_path, notice: "#{created}件のデジタル遺品リストを生成しました"
  rescue => e
    redirect_to digital_items_path, alert: "AIリスト生成に失敗しました。もう一度お試しください。"
  end

  private

  def set_digital_item
    @digital_item = current_user.digital_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def digital_item_params
    params.require(:digital_item).permit(:category, :service_name, :status, :priority, :notes)
  end
end
