class GuestAssessmentsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    @remaining = guest_remaining
  end

  def create
    unless user_signed_in?
      session_obj = guest_session_record
      if session_obj.limit_reached?
        @remaining = 0
        flash.now[:alert] = "無料査定の上限（#{session_obj.limit}回）に達しました。会員登録すると無制限でご利用いただけます。"
        render :new and return
      end
    end

    files = Array(params[:images]).reject(&:blank?)
    unless files.any?
      flash.now[:alert] = "写真を選んでください"
      @remaining = guest_remaining
      render :new, status: :unprocessable_entity and return
    end

    images = files.map { |f| { data: f.read, content_type: f.content_type } }

    @result = AiAssessmentService.assess_upload(
      images: images,
      name: params[:name].presence,
      memo: params[:memo].presence
    )

    # 査定成功時のみカウントを加算する（失敗はカウントしない）
    guest_session_record.add_items(1) if !user_signed_in? && @result[:success]

    if @result[:processed_images]&.any?
      @uploaded_images = @result[:processed_images].map do |img|
        { data: Base64.strict_encode64(img[:data]), content_type: img[:content_type] }
      end
    else
      @uploaded_images = images.map do |img|
        { data: Base64.strict_encode64(img[:data]), content_type: img[:content_type] }
      end
    end
  end

  private

  def guest_token
    session[:guest_token] ||= SecureRandom.hex(16)
  end

  def guest_session_record
    @guest_session ||= GuestAssessmentSession.find_or_create_for(guest_token)
  end

  def guest_remaining
    return nil if user_signed_in?
    guest_session_record.remaining
  end
end
