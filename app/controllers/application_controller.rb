class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :role, :prefecture, :city ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def require_admin!
    redirect_to root_path, alert: "アクセス権限がありません" unless current_user&.admin?
  end

  def require_business!
    redirect_to root_path, alert: "業者アカウントが必要です" unless current_user&.business?
  end
end
