class GuestAssessmentsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
  end

  def create
    files = Array(params[:images]).reject(&:blank?)
    unless files.any?
      flash.now[:alert] = "写真を選んでください"
      render :new, status: :unprocessable_entity and return
    end

    images = files.map { |f| { data: f.read, content_type: f.content_type } }

    @result = AiAssessmentService.assess_upload(
      images: images,
      name: params[:name].presence,
      memo: params[:memo].presence
    )

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
end
