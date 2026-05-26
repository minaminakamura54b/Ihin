class BulkAssessmentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create, :show, :progress ]
  before_action :set_bulk_assessment, only: [ :show, :progress, :retry_item ]
  before_action :check_rate_limit,    only: [ :create ]

  ITEMS_PER_BATCH  = 5
  HOURLY_LIMIT     = 10  # 登録済みユーザーの1時間あたり上限

  def new
    @remaining = guest_remaining
  end

  def create
    items_params = parse_items_params
    item_count   = items_params.size

    if item_count.zero?
      flash.now[:alert] = "遺品を1点以上追加してください（写真または名前が必要です）"
      @remaining = guest_remaining
      render :new, status: :unprocessable_entity and return
    end

    if item_count > ITEMS_PER_BATCH
      flash.now[:alert] = "一度に査定できるのは#{ITEMS_PER_BATCH}点までです"
      @remaining = guest_remaining
      render :new, status: :unprocessable_entity and return
    end

    # 未登録ユーザーの累計制限チェック
    unless user_signed_in?
      session_obj = guest_session_record
      if session_obj.limit_reached?
        @show_limit_modal = true
        @remaining = 0
        render :new and return
      end
      available = session_obj.remaining
      if item_count > available
        flash.now[:alert] = "残り#{available}点のみ無料で査定できます"
        @remaining = available
        render :new, status: :unprocessable_entity and return
      end
    end

    bulk = BulkAssessment.transaction do
      b = BulkAssessment.create!(
        user:          user_signed_in? ? current_user : nil,
        session_token: user_signed_in? ? nil : guest_token
      )

      items_params.each_with_index do |item_p, i|
        bai = b.bulk_assessment_items.create!(
          name:     item_p[:name]&.strip&.slice(0, 255),
          memo:     item_p[:memo]&.strip&.slice(0, 500),
          position: i + 1
        )
        photos = item_p[:photos].reject(&:blank?)
        bai.photos.attach(photos) if photos.any?
      end

      guest_session_record.add_items(item_count) unless user_signed_in?
      b
    end

    BulkAssessmentJob.perform_later(bulk.id)
    redirect_to bulk_assessment_path(bulk)
  end

  def show
    @items = @bulk.bulk_assessment_items.order(:position)
  end

  def progress
    items = @bulk.bulk_assessment_items.order(:position).map do |item|
      {
        id:              item.id,
        name:            item.display_name,
        status:          item.status,
        estimated_price: item.estimated_price,
        suggested_action: item.suggested_action,
        action_label:    item.action_label,
        ai_result:       item.ai_result,
        error_message:   item.error_message
      }
    end

    render json: {
      status:                @bulk.status,
      completed:             @bulk.completed_count,
      total:                 @bulk.total_count,
      total_estimated_price: @bulk.total_estimated_price,
      total_sell_price:      @bulk.total_sell_price,
      items:                 items
    }
  end

  def retry_item
    item = @bulk.bulk_assessment_items.find(params[:item_id])
    item.update!(status: :pending, error_message: nil, ai_result: nil, estimated_price: nil, suggested_action: nil)

    @bulk.update!(status: :pending) if @bulk.completed?

    BulkAssessmentJob.perform_later(@bulk.id)
    redirect_to bulk_assessment_path(@bulk), notice: "再試行を開始しました"
  rescue ActiveRecord::RecordNotFound
    redirect_to bulk_assessment_path(@bulk), alert: "該当の遺品が見つかりません"
  end

  private

  def set_bulk_assessment
    scope = user_signed_in? ? BulkAssessment.where(user: current_user)
                            : BulkAssessment.where(session_token: guest_token)
    @bulk = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "査定が見つかりません"
  end

  # 登録済みユーザーの1時間あたりレートリミット
  def check_rate_limit
    return unless user_signed_in?
    recent = current_user.bulk_assessments
                         .where("created_at > ?", 1.hour.ago)
                         .count
    if recent >= HOURLY_LIMIT
      @remaining = nil
      flash.now[:alert] = "1時間あたりの査定回数の上限（#{HOURLY_LIMIT}回）に達しました。しばらく時間をおいてください。"
      render :new, status: :too_many_requests
    end
  end

  def parse_items_params
    return [] unless params[:items].present?
    params[:items].to_unsafe_h.values.map do |item|
      {
        name:   item["name"],
        memo:   item["memo"],
        photos: Array(item["photos"])
      }
    end.reject { |i| i[:photos].all?(&:blank?) && i[:name].blank? }
  end

  def guest_session_record
    @guest_session ||= GuestAssessmentSession.find_or_create_for(guest_token)
  end

  def guest_token
    session[:guest_token] ||= SecureRandom.hex(16)
  end

  def guest_remaining
    return nil if user_signed_in?
    guest_session_record.remaining
  end
end
