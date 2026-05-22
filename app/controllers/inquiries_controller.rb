class InquiriesController < ApplicationController
  before_action :set_business
  before_action :set_inquiry, only: [:update]

  def index
    unless @business.user == current_user
      redirect_to root_path, alert: "権限がありません" and return
    end
    @inquiries = @business.inquiries.includes(:user).order(created_at: :desc)
  end

  def create
    @inquiry = current_user.inquiries.new(inquiry_params)
    @inquiry.business = @business

    if @inquiry.save
      redirect_to @business, notice: "お問い合わせを送信しました。業者からのご連絡をお待ちください。"
    else
      redirect_to @business, alert: "送信に失敗しました"
    end
  end

  def update
    unless @business.user == current_user
      redirect_to root_path, alert: "権限がありません" and return
    end
    @inquiry.update(status: params.dig(:inquiry, :status))
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "inquiry_status_#{@inquiry.id}",
          partial: "businesses/inquiry_status_badge",
          locals: { inquiry: @inquiry }
        )
      end
      format.html { redirect_to dashboard_business_path(@business) }
    end
  end

  private

  def set_business
    @business = Business.find(params[:business_id])
  end

  def set_inquiry
    @inquiry = @business.inquiries.find(params[:id])
  end

  def inquiry_params
    params.require(:inquiry).permit(:message)
  end
end
