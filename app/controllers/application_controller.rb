class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :verify_session_token       # パスワード変更・ロール変更後の強制ログアウト
  before_action :verify_user_agent          # セッションハイジャック検知
  before_action :rotate_remember_token      # remember_meトークンを定期ローテーション
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

  # ===== セッショントークン検証 =====
  # パスワード変更・ロール変更時にsession_tokenが更新されるため
  # 他デバイスのセッションは次のリクエストで自動的に無効になる
  def verify_session_token
    return unless user_signed_in?
    return if devise_controller?

    stored_token = session[:user_session_token]

    if stored_token.present? && stored_token != current_user.session_token
      sign_out current_user
      reset_session
      redirect_to new_user_session_path,
        alert: "セッションが無効になりました。再度ログインしてください。" and return
    end

    # セッションにトークンがない場合は初期化（remember_me経由での復元時など）
    session[:user_session_token] ||= current_user.session_token
  end

  # ===== User-Agentフィンガープリント検証 =====
  # セッションハイジャックを検知する：
  # ① セッション内のUAと現在のUAが異なる → 同一セッションを別環境で利用
  # ② DBのUAと現在のUAが異なる → remember_meトークンが盗まれた可能性
  def verify_user_agent
    return unless user_signed_in?
    return if devise_controller?

    current_fp = compute_ua_fingerprint

    # セッション内フィンガープリントの検証（セッション固定・ハイジャック対策）
    session_fp = session[:user_agent_fingerprint]
    if session_fp.present? && session_fp != current_fp
      handle_suspicious_access(
        "セッション内でUser-Agentが変更されました",
        current_fp
      )
      return
    end

    # DBフィンガープリントの検証（remember_meトークン盗用対策）
    # セッションにUAがない = remember_me経由での新規セッション開始
    if session_fp.blank? && current_user.user_agent_fingerprint.present?
      db_fp = current_user.user_agent_fingerprint
      if db_fp != current_fp
        handle_suspicious_access(
          "remember_meトークン使用時にUser-Agentが前回ログインと異なります",
          current_fp
        )
        return
      end
    end

    # セッションにUAがない場合は初期化（以降の検証に使用）
    session[:user_agent_fingerprint] ||= current_fp
  end

  # ===== remember_meトークンのローテーション =====
  # 盗まれたトークンを無効化するため、24時間ごとに新しいトークンを発行する
  def rotate_remember_token
    return unless user_signed_in?
    # remember_meが有効なセッションのみ対象
    return unless current_user.remember_created_at.present?

    last_rotated = session[:remember_rotated_at]
    # 24時間経過していればローテーション
    if last_rotated.blank? || Time.parse(last_rotated.to_s) < 24.hours.ago
      # Deviseのremember_meトークンを更新（新しいCookieが自動的に発行される）
      current_user.remember_me!
      # 新しいCookieを明示的にセット
      cookies.signed["remember_user_token"] = {
        value:     current_user.rememberable_value,
        expires:   Devise.remember_for.from_now,
        httponly:  true,
        secure:    Rails.env.production?,
        same_site: :strict
      }
      session[:remember_rotated_at] = Time.current.iso8601
    end
  end

  # ===== 不審アクセスの処理 =====
  def handle_suspicious_access(reason, current_fp)
    Rails.logger.warn "[SECURITY] 不審アクセス検知 user_id=#{current_user.id} " \
                      "reason=#{reason} ip=#{request.ip} ua=#{request.user_agent.to_s.truncate(100)}"

    # 非同期でメール通知（メール送信失敗でもログアウトは継続）
    begin
      SecurityMailer.suspicious_access(
        current_user,
        request.user_agent,
        request.ip
      ).deliver_later
    rescue => e
      Rails.logger.error "[SECURITY] メール送信失敗: #{e.message}"
    end

    sign_out current_user
    reset_session
    redirect_to new_user_session_path,
      alert: "不審なアクセスを検知したため、安全のためログアウトしました。" \
             "心当たりがない場合はパスワードを変更してください。" and return
  end

  # User-Agentの先頭200文字のSHA-256ハッシュ（16文字）
  def compute_ua_fingerprint
    Digest::SHA256.hexdigest(request.user_agent.to_s.truncate(200))[0, 16]
  end

  # ===== 審査ステータスに応じて業者ユーザーのアクセスを制御 =====
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
      return if controller_name == "businesses" && action_name == "pending"
      redirect_to pending_businesses_path
    end
  end
end
