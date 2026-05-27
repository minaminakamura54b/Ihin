class ConsultationsController < ApplicationController
  before_action :check_consultation_limit, only: [ :create ]

  def index
    @consultations = current_user.consultations.recent
  end

  def create
    message = params[:message].to_s.strip
    history = parse_history(params[:history])

    return render json: { error: "メッセージを入力してください" }, status: :unprocessable_entity if message.blank?

    result = AiConsultationService.new.ask(message, history)

    if result[:success]
      current_user.consultations.create!(message: message, response: result[:answer])
      respond_to do |format|
        format.turbo_stream do
          @user_message = message
          @ai_answer = result[:answer]
        end
        format.json { render json: { answer: result[:answer] } }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          @user_message = message
          @ai_answer = "申し訳ありません。しばらく経ってからもう一度お試しください。"
        end
        format.json { render json: { error: result[:error] }, status: :unprocessable_entity }
      end
    end
  end

  private

  def check_consultation_limit
    if current_user.consultations.where("created_at > ?", 1.hour.ago).count >= 20
      render json: { error: "しばらく時間をおいてから試してください" }, status: :too_many_requests
    end
  end

  def parse_history(history_param)
    parsed = history_param.is_a?(String) ? JSON.parse(history_param) : history_param
    return [] unless parsed.is_a?(Array)
    parsed.map { |h| { role: h["role"] || h[:role], content: h["content"] || h[:content] } }.compact
  rescue
    []
  end
end
