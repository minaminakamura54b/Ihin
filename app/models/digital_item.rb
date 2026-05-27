class DigitalItem < ApplicationRecord
  belongs_to :user

  enum :category, {
    sns:          0,  # SNS・メール
    subscription: 1,  # サブスク・有料サービス
    device:       2,  # スマホ・PC・デバイス
    other:        3   # その他
  }

  enum :status, {
    unchecked:   0,  # 未対応
    in_progress: 1,  # 対応中
    completed:   2   # 完了
  }

  validates :service_name, presence: true, length: { maximum: 100 }
  validates :priority, inclusion: { in: 1..3 }
  validates :notes, length: { maximum: 500 }, allow_blank: true

  scope :by_priority, -> { order(priority: :asc, created_at: :asc) }

  # カテゴリの日本語ラベル
  CATEGORY_LABELS = {
    "sns"          => "SNS・メール",
    "subscription" => "サブスク・有料サービス",
    "device"       => "スマホ・PC・デバイス",
    "other"        => "その他"
  }.freeze

  # カテゴリアイコン
  CATEGORY_ICONS = {
    "sns"          => "fa-comments",
    "subscription" => "fa-credit-card",
    "device"       => "fa-mobile-alt",
    "other"        => "fa-folder"
  }.freeze

  # デフォルトサービスリスト
  DEFAULT_SERVICES = {
    sns: %w[LINE Instagram Facebook Twitter(X) Gmail Yahoo!メール],
    subscription: [ "Netflix", "Amazon Prime", "Spotify", "Apple Music", "楽天", "Amazon", "各種保険" ],
    device: [ "iPhone", "Android", "iPad", "PC", "マイナンバーカード", "各種ポイントカード" ]
  }.freeze

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def category_icon
    CATEGORY_ICONS[category] || "fa-folder"
  end

  def priority_label
    case priority
    when 1 then "高"
    when 2 then "中"
    when 3 then "低"
    end
  end
end
