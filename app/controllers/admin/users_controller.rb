class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
  end

  def edit
  end

  def update
    if @user == current_user && user_params[:role].present? && user_params[:role] != "admin"
      redirect_to admin_user_path(@user), alert: "自分自身の権限を変更することはできません" and return
    end
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "自分自身のアカウントは削除できません" and return
    end
    @user.destroy
    redirect_to admin_users_path, notice: "削除しました"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :role)
  end
end
