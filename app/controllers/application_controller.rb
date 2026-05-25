class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_business_approval_status

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
      keys: [ :name, :prefecture, :city ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def require_admin!
    redirect_to root_path, alert: "アクセス権限がありません" unless current_user&.admin?
  end

  def require_business!
    redirect_to root_path, alert: "業者アカウントが必要です" unless current_user&.business?
  end

  private

  # 審査ステータスに応じて業者ユーザーのアクセスを制御する
  def check_business_approval_status
    return unless user_signed_in? && current_user.business?
    return if devise_controller?
    return if controller_path.start_with?("rails/")

    biz = current_user.business
    return unless biz.present?

    if biz.rejected?
      sign_out current_user
      redirect_to root_path,
        alert: "申請が却下されました。詳細はメールをご確認ください。" and return
    end

    unless biz.approved?
      # 審査待ちページ自体への無限リダイレクトを防ぐ
      return if controller_name == "businesses" && action_name == "pending"
      redirect_to pending_businesses_path
    end
  end
end
