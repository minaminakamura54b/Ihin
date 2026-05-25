class BusinessesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show, :for_estate_clearance, :for_resellers, :select_type, :email_sent ]
  # 審査待ちページは check_business_approval_status のループ回避のため skip しない（ApplicationControllerで制御済み）
  before_action :set_business, only: [:show, :edit, :update, :destroy, :subscribe, :unsubscribe, :dashboard]
  before_action :authorize_business!, only: [:edit, :update, :destroy, :subscribe, :unsubscribe]
  before_action :require_business_role, only: [:dashboard]
  before_action :require_business_owner!, only: [:dashboard]

  def index
    @businesses = BusinessMatcher.find_for(
      current_user,
      category: params[:category]
    )
  end

  def select_type
    # 業種選択画面（ログイン不要）
  end

  def email_sent
    # 登録後のメール確認待ち案内画面（ログイン不要）
  end

  def pending
    # 審査待ち画面（ログイン必須、ApplicationControllerで業者のみアクセス可）
    @business = current_user.business
  end

  def for_estate_clearance
  end

  def for_resellers
  end

  def search
    @businesses = Business.active.includes(:user)
    @businesses = @businesses.where(category: params[:category]) if params[:category].present?
    @businesses = @businesses.where("area LIKE ?", "%#{params[:area]}%") if params[:area].present?
    @businesses = @businesses.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
    @businesses = @businesses.page(params[:page]).per(12)
    render :index
  end

  def show
    @inquiry = Inquiry.new if user_signed_in?
  end

  def new
    @business = current_user.build_business
  end

  def create
    @business = current_user.build_business(business_params)
    if @business.save
      redirect_to @business, notice: "業者情報を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @business.update(business_params)
      redirect_to @business, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @business.destroy
    redirect_to root_path, notice: "削除しました"
  end

  def subscribe
    plan = params[:plan]

    if @business.free? && plan == "free"
      redirect_to dashboard_business_path(@business), alert: "すでに無料プランです"
      return
    end

    service = StripeSubscriptionService.new(current_user, @business)
    result = service.create_subscription(plan)

    if result[:success]
      @business.update!(plan: plan)
      redirect_to dashboard_business_path(@business), notice: "#{@business.plan_label}に変更しました"
    else
      redirect_to dashboard_business_path(@business), alert: "決済処理中にエラーが発生しました: #{result[:error]}"
    end
  end

  def dashboard
    this_month = Time.current.beginning_of_month..Time.current.end_of_month
    @inquiries         = @business.inquiries.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
    @pending_count     = @business.inquiries.pending.count
    @contacted_count   = @business.inquiries.contacted.count
    @closed_count      = @business.inquiries.closed.where(created_at: this_month).count
    @monthly_new_count = @business.inquiries.where(created_at: this_month).count
    @plan = @business.plan
    limit = @business.contact_limit
    @remaining_contacts = limit ? [limit - @monthly_new_count, 0].max : nil
    @sidebar_pending = @business.inquiries.pending.includes(:user).order(created_at: :desc).limit(5)
  end

  def unsubscribe
    service = StripeSubscriptionService.new(current_user, @business)
    result = service.cancel_subscription

    if result[:success]
      redirect_to @business, notice: "サブスクリプションをキャンセルしました"
    else
      redirect_to @business, alert: "キャンセル処理中にエラーが発生しました: #{result[:error]}"
    end
  end

  private

  def set_business
    @business = Business.find(params[:id])
  end

  def authorize_business!
    redirect_to root_path, alert: "権限がありません" unless @business.user == current_user || current_user.admin?
  end

  def require_business_role
    unless current_user&.business?
      redirect_to root_path, alert: "業者アカウントでログインしてください"
    end
  end

  def require_business_owner!
    unless @business.user == current_user
      redirect_to root_path, alert: "権限がありません"
    end
  end

  def business_params
    params.require(:business).permit(:name, :category, :area, :description, :phone, :website, :plan)
  end
end
