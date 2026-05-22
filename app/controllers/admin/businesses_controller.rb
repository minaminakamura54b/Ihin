class Admin::BusinessesController < Admin::BaseController
  before_action :set_business, only: [ :show, :edit, :update, :destroy, :approve, :reject ]

  def index
    @businesses = Business.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
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

  private

  def set_business
    @business = Business.find(params[:id])
  end

  def business_params
    params.require(:business).permit(:name, :category, :area, :description, :phone, :website, :plan, :active)
  end
end
