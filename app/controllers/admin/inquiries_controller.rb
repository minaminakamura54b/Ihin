class Admin::InquiriesController < Admin::BaseController
  before_action :set_inquiry, only: [ :show, :update ]

  def index
    @inquiries = Inquiry.includes(:user, :business).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
  end

  def update
    unless Inquiry.statuses.key?(params[:status])
      redirect_to admin_inquiry_path(@inquiry), alert: "無効なステータスです" and return
    end
    @inquiry.update!(status: params[:status])
    redirect_to admin_inquiry_path(@inquiry), notice: "ステータスを更新しました"
  end

  private

  def set_inquiry
    @inquiry = Inquiry.find(params[:id])
  end
end
