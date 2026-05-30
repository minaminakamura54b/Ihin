class Inquiry < ApplicationRecord
  belongs_to :user
  belongs_to :business
  belongs_to :item, optional: true

  enum :status,       { pending: 0, contacted: 1, closed: 2 }
  enum :contact_type, { email: 0, phone: 1 }

  validates :message,      presence: true
  # 以下3つは新規作成時のみ検証（業者のステータス更新に影響させない）
  validates :contact_info, presence: true, on: :create
  validate  :validate_contact_info_format, on: :create
  validate  :validate_no_duplicate_within_24h, on: :create

  private

  # メール形式 or 電話番号形式のチェック
  def validate_contact_info_format
    return if contact_info.blank?

    if email?
      unless contact_info.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
        errors.add(:contact_info, "のメールアドレスの形式が正しくありません")
      end
    elsif phone?
      # ハイフンあり・なし両方許容（例: 090-1234-5678 / 09012345678）
      unless contact_info.gsub("-", "").match?(/\A0\d{9,10}\z/)
        errors.add(:contact_info, "の電話番号の形式が正しくありません（例：090-1234-5678）")
      end
    end
  end

  # 同一業者への24時間以内の重複問い合わせを防止
  def validate_no_duplicate_within_24h
    return unless user && business

    if user.inquiries.where(business: business)
                     .where("created_at > ?", 24.hours.ago)
                     .exists?
      errors.add(:base, "同じ業者への問い合わせは24時間以内に1回までです")
    end
  end
end
