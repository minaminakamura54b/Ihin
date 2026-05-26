class MemoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :shared ]
  before_action :set_memory,      only: [ :show, :edit, :update, :destroy, :generate_ai_summary, :toggle_share ]
  before_action :set_by_token,    only: [ :shared ]

  def index
    @memories   = current_user.memories.includes(:item).order(created_at: :desc).page(params[:page]).per(12)
    @total      = @memories.total_count
    @ai_summary = current_user.memories.where.not(ai_summary: nil).order(updated_at: :desc).first&.ai_summary
  end

  def show
  end

  def new
    @memory = current_user.memories.new
    @memory.item_id = params[:item_id]
  end

  def create
    @memory = current_user.memories.new(memory_params)
    if @memory.save
      redirect_to memories_path, notice: "思い出を保存しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @memory.update(memory_params)
      redirect_to @memory, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @memory.destroy
    redirect_to memories_path, notice: "削除しました"
  end

  # AIが追悼文を生成してai_summaryに保存する
  def generate_ai_summary
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

    description_text = [@memory.title, @memory.description, @memory.comment].compact.join("\n")
    if description_text.blank?
      redirect_to @memory, alert: "エピソードを入力してからAI追悼文を生成してください" and return
    end

    prompt = <<~PROMPT
      以下の遺品と思い出をもとに、温かく美しい追悼文を生成してください。
      遺族の気持ちに寄り添った200〜300文字の文章にしてください。
      文章は日本語で書いてください。

      遺品・思い出の情報：
      #{description_text}
    PROMPT

    response = client.messages.create(
      model:      "claude-sonnet-4-5",
      max_tokens: 512,
      messages:   [ { role: "user", content: prompt } ]
    )

    @memory.update!(ai_summary: response.content.first.text.strip)
    redirect_to @memory, notice: "AI追悼文を生成しました"
  rescue => e
    redirect_to @memory, alert: "AI追悼文の生成に失敗しました。もう一度お試しください。"
  end

  # 共有のON/OFFを切り替える
  def toggle_share
    @memory.update!(shared: !@memory.shared)
    respond_to do |format|
      format.html { redirect_to @memory, notice: @memory.shared? ? "共有URLを発行しました" : "共有を停止しました" }
      format.turbo_stream
    end
  end

  # ログイン不要の共有ページ（share_tokenでアクセス）
  def shared
    # @memory は before_action :set_by_token でセット済み
  end

  private

  def set_memory
    @memory = current_user.memories.find(params[:id])
  end

  def set_by_token
    @memory = Memory.find_by!(share_token: params[:token], shared: true)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "このページは存在しないか、共有が停止されています"
  end

  def memory_params
    params.require(:memory).permit(:item_id, :comment, :photo, :title, :description, :shared)
  end
end
