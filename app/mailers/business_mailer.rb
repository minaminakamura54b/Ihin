class BusinessMailer < ApplicationMailer
  # 審査中通知（メール確認完了後に自動送信）
  def under_review(business)
    @business = business
    @user     = business.user
    mail(
      to:      @user.email,
      subject: "【遺品AI査定】掲載申請を受け付けました"
    )
  end

  # 承認通知（管理者が承認した時に送信）
  def approved(business)
    @business = business
    @user     = business.user
    mail(
      to:      @user.email,
      subject: "【遺品AI査定】掲載申請が承認されました"
    )
  end

  # 却下通知（管理者が却下した時に送信）
  def rejected(business)
    @business = business
    @user     = business.user
    mail(
      to:      @user.email,
      subject: "【遺品AI査定】掲載申請についてのご連絡"
    )
  end
end
