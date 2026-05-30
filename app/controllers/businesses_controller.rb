class BusinessesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show, :search, :for_estate_clearance, :for_resellers, :select_type, :email_sent ]
  # 審査待ちページは check_business_approval_status のループ回避のため skip しない（ApplicationControllerで制御済み）
  before_action :set_business, only: [ :show, :edit, :update, :destroy, :subscribe, :unsubscribe, :dashboard ]
  before_action :authorize_business!, only: [ :edit, :update, :destroy, :subscribe, :unsubscribe ]
  before_action :require_business_role, only: [ :dashboard ]
  before_action :require_business_owner!, only: [ :dashboard ]

  def index
    @prefecture = params[:prefecture]

    if @prefecture.present?
      # service_prefectures 配列に選択した都道府県が含まれる業者を検索
      base = Business.active.approved
                    .where("? = ANY(service_prefectures)", @prefecture)
      base = base.where(category: params[:category]) if params[:category].present?
      @businesses = base.order(plan: :desc).page(params[:page]).per(12)
    else
      @businesses = Business.none
    end
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
    @step = params[:step] || "1"
    @category = params[:category]
    @prefecture = params[:prefecture]

    if @step == "3" && @category.present? && @prefecture.present?
      # STEP3: カテゴリ＋service_prefectures で絞り込み
      @businesses = Business.active.approved
                            .where(category: @category)
                            .where("? = ANY(service_prefectures)", @prefecture)
                            .order(plan: :desc)
                            .page(params[:page]).per(12)
    end
  end

  def show
    return unless user_signed_in?

    # 24時間以内に同一業者への問い合わせ済みかどうか
    @already_inquired = current_user.inquiries
                                    .where(business: @business)
                                    .where("created_at > ?", 24.hours.ago)
                                    .exists?
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

    @inquiries = @business.inquiries.includes(:user).order(created_at: :desc).page(params[:page]).per(20)

    # ステータス別カウントを1クエリで取得
    status_counts  = @business.inquiries.group(:status).count
    @pending_count   = status_counts["pending"]   || 0
    @contacted_count = status_counts["contacted"] || 0

    # 当月カウントを1クエリで取得
    monthly_counts = @business.inquiries.where(created_at: this_month).group(:status).count
    @closed_count      = monthly_counts["closed"] || 0
    @monthly_new_count = monthly_counts.values.sum

    limit = @business.contact_limit
    @remaining_contacts = limit ? [ limit - @monthly_new_count, 0 ].max : nil
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
    params.require(:business).permit(:name, :category, :area, :description, :phone, :website, :plan, service_prefectures: [])
  end
end
