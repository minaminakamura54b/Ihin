class Business < ApplicationRecord
  belongs_to :user
  has_many :inquiries, dependent: :destroy

  # 業種（既存 0-2 を維持、新規 3-4 を追加）
  enum :category, {
    estate_clearance:  0,
    buyback:           1,
    judicial_scrivener: 2,
    real_estate:       3,
    tax_accountant:    4
  }

  enum :plan, { free: 0, basic: 1, standard: 2, premium: 3 }

  enum :approval_status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates :name, presence: true
  validates :user, presence: true

  scope :active,    -> { where(active: true) }
  scope :pending,   -> { where(approval_status: 0) }
  scope :approved,  -> { where(approval_status: 1) }
  scope :rejected,  -> { where(approval_status: 2) }

  FREE_PERIOD_DAYS = 90

  MONTHLY_PRICES = {
    "free"     => 0,
    "basic"    => 10_000,
    "standard" => 30_000,
    "premium"  => 50_000
  }.freeze

  CONTACT_LIMITS = {
    "free"     => 2,
    "basic"    => 10,
    "standard" => 30,
    "premium"  => Float::INFINITY
  }.freeze

  # 業種ごとの許可証ラベル
  LICENSE_LABELS = {
    "estate_clearance"   => "古物商許可証番号",
    "buyback"            => "古物商許可証番号",
    "real_estate"        => "宅建業免許番号",
    "tax_accountant"     => "税理士登録番号",
    "judicial_scrivener" => "司法書士登録番号"
  }.freeze

  def category_label
    case category
    when "estate_clearance"   then "遺品整理業者"
    when "buyback"            then "買取業者"
    when "judicial_scrivener" then "司法書士"
    when "real_estate"        then "不動産業者"
    when "tax_accountant"     then "税理士"
    else category
    end
  end

  def approval_status_label
    case approval_status
    when "pending"  then "審査待ち"
    when "approved" then "承認済み"
    when "rejected" then "却下"
    else approval_status
    end
  end

  def license_label
    LICENSE_LABELS[category] || "許可証・登録番号"
  end

  def plan_label
    case plan
    when "free"     then "無料プラン（3ヶ月限定）"
    when "basic"    then "ベーシック（月額1万円）"
    when "standard" then "スタンダード（月額3万円）"
    when "premium"  then "プレミアム（月額5万円）"
    else plan
    end
  end

  def monthly_price
    MONTHLY_PRICES[plan] || 0
  end

  # 無料期間（90日）がまだ有効かどうか
  def free_period_active?
    free? && created_at > FREE_PERIOD_DAYS.days.ago
  end

  # 無料期間の残り日数
  def free_period_remaining_days
    return 0 unless free_period_active?
    ((created_at + FREE_PERIOD_DAYS.days - Time.current) / 1.day).to_i
  end

  # プランに応じた月間連絡可能件数
  def contact_limit
    CONTACT_LIMITS[plan] || 2
  end

  # 今月まだ連絡できるか
  def can_contact?
    inquiries.where(
      created_at: Time.current.beginning_of_month..Time.current.end_of_month
    ).count < contact_limit
  end

end
