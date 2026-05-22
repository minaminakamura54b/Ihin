class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_root_path
    elsif resource.business?
      biz = resource.business
      biz&.persisted? ? dashboard_business_path(biz) : new_business_path
    else
      root_path
    end
  end
end
