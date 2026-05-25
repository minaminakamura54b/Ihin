class Users::ConfirmationsController < Devise::ConfirmationsController
  private

  # メール確認後のリダイレクト先を業者ユーザーのみ変更する
  def after_confirmation_path_for(resource_name, resource)
    if resource.business?
      # 審査中メールを送信
      BusinessMailer.under_review(resource.business).deliver_later
      sign_in(resource_name, resource)
      pending_businesses_path
    else
      super
    end
  end
end
