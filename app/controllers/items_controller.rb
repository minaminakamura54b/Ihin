class ItemsController < ApplicationController
  before_action :set_item, only: [ :show, :edit, :update, :destroy, :assess, :update_action ]

  def index
    @items = current_user.items
    @items = @items.where(action: params[:action_filter]) if params[:action_filter].present? && params[:action_filter] != "undecided"
    @items = @items.where(action: 0) if params[:action_filter] == "undecided"
    @items = @items.order(created_at: :desc).page(params[:page]).per(12)
    @assessed_count = current_user.items.assessed.count
    @total_count = current_user.items.count
  end

  def show
  end

  def new
    @item = current_user.items.new
  end

  def create
    @item = current_user.items.new(item_params)
    if @item.save
      redirect_to item_path(@item), notice: "遺品を登録しました。AI査定ボタンを押してください。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to items_path, notice: "削除しました"
  end

  def assess
    assessment_service = AiAssessmentService.new(@item)
    result = assessment_service.assess

    if result[:success]
      safe_action = Item.actions.key?(result[:suggested_action]) ? result[:suggested_action] : "undecided"
      @item.update(
        ai_result: result[:ai_result],
        estimated_price: result[:estimated_price],
        action: safe_action,
        name: result[:item_name] || @item.name
      )
      respond_to do |format|
        format.html { redirect_to @item, notice: "AI査定が完了しました" }
        format.turbo_stream
      end
    else
      @assessment_error = result[:error]
      respond_to do |format|
        format.html { redirect_to @item, alert: "査定中にエラーが発生しました: #{result[:error]}" }
        format.turbo_stream
      end
    end
  end

  def update_action
    unless Item.actions.key?(params[:action_type])
      head :unprocessable_entity and return
    end
    if @item.update(action: params[:action_type])
      respond_to do |format|
        format.html { redirect_to @item, notice: "分類を更新しました" }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("item_#{@item.id}_action", partial: "items/action_badge", locals: { item: @item }) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_item
    @item = current_user.items.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :memo, images: [])
  end
end
