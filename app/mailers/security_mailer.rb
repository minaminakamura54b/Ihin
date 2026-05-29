class SecurityMailer < ApplicationMailer
  # 不審なアクセスをユーザーに通知する
  def suspicious_access(user, user_agent, ip_address, detected_at = Time.current)
    @user        = user
    @user_agent  = user_agent.to_s.truncate(200)
    @ip_address  = ip_address
    @detected_at = detected_at.in_time_zone("Tokyo")

    mail(
      to:      @user.email,
      subject: "【重要】不審なアクセスを検知しました - 遺品AI査定"
    )
  end
end
