class Users::SessionsController < Devise::SessionsController
  # ログイン処理：セッション固定攻撃対策のためセッションIDを再生成
  def create
    # ログイン前に転送先URLを退避（reset_session後も維持するため）
    return_path = session[:user_return_to]

    super do |resource|
      next unless resource.persisted?

      # セッション固定攻撃対策：
      # ① 認証前の古いセッションを完全に破棄（Cookieストアの暗号化値も変わる）
      reset_session

      # ② Wardenに認証済みユーザーを再登録（reset_sessionで消えた認証情報を復元）
      warden.set_user(resource, scope: resource_name)

      # ③ 転送先URLを新セッションに復元
      session[:user_return_to] = return_path if return_path

      # ④ セキュリティ情報を新セッションに保存
      session[:user_session_token]     = resource.session_token
      session[:user_agent_fingerprint] = compute_ua_fingerprint

      # ⑤ User-AgentフィンガープリントをDBに保存（remember_me経由での再ログイン検証用）
      resource.update_column(:user_agent_fingerprint, compute_ua_fingerprint)
    end
  end

  # ログアウト時にセッションを完全に破棄
  def destroy
    super
    reset_session
  end

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

  private

  # User-Agentの先頭200文字のSHA-256ハッシュ（16文字）を返す
  # 完全な文字列ではなくハッシュにすることでDBサイズを抑える
  def compute_ua_fingerprint
    Digest::SHA256.hexdigest(request.user_agent.to_s.truncate(200))[0, 16]
  end
end
