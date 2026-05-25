class Admin::BusinessesController < Admin::BaseController
  before_action :set_business, only: [ :show, :edit, :update, :destroy, :approve, :reject ]

  def index
    @businesses = Business.includes(:user)

    # ステータスフィルター
    if params[:status].present? && Business.approval_statuses.key?(params[:status])
      @businesses = @businesses.where(approval_status: params[:status])
    end

    @businesses = @businesses.order(created_at: :desc).page(params[:page]).per(20)
    @pending_count = Business.pending.count
  end

  def show
  end

  def edit
  end

  def update
    if @business.update(business_params)
      redirect_to admin_business_path(@business), notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @business.destroy
    redirect_to admin_businesses_path, notice: "削除しました"
  end

  def approve
    @business.update!(approval_status: :approved, active: true, rejected_reason: nil)
    BusinessMailer.approved(@business).deliver_later
    redirect_to admin_business_path(@business), notice: "#{@business.name} を承認しました"
  end

  def reject
    reason = params[:reason].to_s.strip
    if reason.blank?
      redirect_to admin_business_path(@business), alert: "却下理由を入力してください" and return
    end
    @business.update!(approval_status: :rejected, active: false, rejected_reason: reason)
    BusinessMailer.rejected(@business).deliver_later
    redirect_to admin_business_path(@business), notice: "#{@business.name} を却下しました"
  end

  private

  def set_business
    @business = Business.find(params[:id])
  end

  def business_params
    params.require(:business).permit(
      :name, :category, :area, :description, :phone, :website,
      :plan, :active, :license_number, :approval_status
    )
  end
end
