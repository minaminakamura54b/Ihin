class Users::RegistrationsController < Devise::RegistrationsController
  ALLOWED_SELF_SIGNUP_ROLES = %w[family business].freeze

  def new
    @role     = params[:role]     || "family"
    @category = params[:category] || "estate_clearance"
    super
  end

  def create
    # バリデーション失敗時にrenderされるnewビューでも業者フォームを維持する
    @role     = params.dig(:user, :role).presence || "family"
    @category = params.dig(:user, :business_category).presence || "estate_clearance"

    # Deviseのデフォルト処理（User作成 + create_free_businessコールバック）を実行
    super do |resource|
      # 業者登録の場合は追加情報でBusinessを更新
      if resource.persisted? && resource.business? && resource.business.present?
        resource.business.update(business_registration_params(resource))
        # メール確認後に審査中通知を送る（under_reviewはConfirmationsController内で送信）
      end
    end
  end

  protected

  def sign_up_params
    base      = super
    role_input = params.dig(:user, :role).to_s
    safe_role  = ALLOWED_SELF_SIGNUP_ROLES.include?(role_input) ? role_input : "family"
    base.merge(role: safe_role)
  end

  def after_sign_up_path_for(resource)
    if resource.business?
      email_sent_businesses_path
    else
      root_path
    end
  end

  # confirmable の場合（未確認状態でのサインアップ後）のリダイレクト先
  def after_inactive_sign_up_path_for(resource)
    if resource.business?
      email_sent_businesses_path
    else
      # familyユーザー：メール確認案内ページへ
      new_user_confirmation_path
    end
  end

  private

  # 業者追加情報のパラメーターを安全に取得する
  def business_registration_params(resource)
    p = params[:user] || {}
    # 会社名が未入力の場合は代表者名を使う
    company_name = p[:company_name].presence || "#{resource.name}の会社"

    # 入力された業種を許可リストで検証
    safe_category = Business.categories.key?(p[:business_category].to_s) ? p[:business_category] : nil

    {
      name:           company_name,
      category:       safe_category,
      phone:          p[:phone],
      area:           p[:area],
      description:    p[:description]&.slice(0, 200),
      license_number: p[:license_number],
      approval_status: :pending,
      active:         false
    }.compact
  end
end
