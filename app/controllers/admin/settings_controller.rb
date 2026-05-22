class Admin::SettingsController < Admin::BaseController
  def index
    @guest_limit = AppSetting.guest_assessment_limit
  end

  def update
    key = params[:key]
    value = params[:value]

    allowed_keys = %w[guest_assessment_limit]
    unless allowed_keys.include?(key)
      redirect_to admin_settings_path, alert: "不正な設定キーです" and return
    end

    AppSetting.set(key, value)
    redirect_to admin_settings_path, notice: "設定を更新しました"
  end
end
