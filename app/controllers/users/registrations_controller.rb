class Users::RegistrationsController < Devise::RegistrationsController
  def new
    @role = params[:role] || "family"
    super
  end

  protected

  def after_sign_up_path_for(resource)
    if resource.admin?
      admin_root_path
    elsif resource.business?
      # 登録時に create_free_business で Business が自動作成される
      dashboard_business_path(resource.business)
    else
      root_path
    end
  end

  def after_update_path_for(resource)
    root_path
  end
end
