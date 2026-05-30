class InquiriesController < ApplicationController
  before_action :set_business
  before_action :set_inquiry, only: [ :update, :complete ]

  def new
    # 24時間以内に同一業者に問い合わせ済みの場合はフォームを表示しない
    if already_inquired?
      redirect_to @business, alert: "同じ業者への問い合わせは24時間以内に1回までです" and return
    end

    @inquiry = @business.inquiries.new(contact_type: :email)
  end

  def create
    @inquiry = current_user.inquiries.new(inquiry_params)
    @inquiry.business = @business

    if @inquiry.save
      # 業者へメール通知
      BusinessMailer.new_inquiry(@business, @inquiry).deliver_later
      # render ではなく redirect（Turbo が POST → 200 を正しく処理しないため）
      redirect_to complete_business_inquiry_path(@business, @inquiry)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def complete
    # 自分の問い合わせ以外はアクセス不可
    unless @inquiry.user == current_user
      redirect_to @business and return
    end
  end

  def index
    unless @business.user == current_user
      redirect_to root_path, alert: "権限がありません" and return
    end
    @inquiries = @business.inquiries.includes(:user).order(created_at: :desc)
  end

  def update
    unless @business.user == current_user
      redirect_to root_path, alert: "権限がありません" and return
    end
    status = params.dig(:inquiry, :status)
    unless Inquiry.statuses.key?(status)
      head :unprocessable_entity and return
    end
    @inquiry.update(status: status)
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
    params.require(:inquiry).permit(:message, :contact_type, :contact_info)
  end

  # 24時間以内に同一業者への問い合わせが存在するか確認
  def already_inquired?
    current_user.inquiries
                .where(business: @business)
                .where("created_at > ?", 24.hours.ago)
                .exists?
  end
end
