class Item < ApplicationRecord
  belongs_to :user
  has_many :memories, dependent: :destroy
  has_many_attached :images

  enum :action, { undecided: 0, sell: 1, keep: 2, dispose: 3, memo: 4 }

  validates :user, presence: true

  scope :assessed, -> { where.not(ai_result: nil) }
  scope :pending_assessment, -> { where(ai_result: nil) }

  def assessed?
    ai_result.present?
  end

  def action_label
    case action
    when "sell"    then "売る"
    when "keep"    then "残す"
    when "dispose" then "処分する"
    when "memo"    then "メモ"
    else "未分類"
    end
  end

  def action_color
    case action
    when "sell"    then "green"
    when "keep"    then "blue"
    when "dispose" then "red"
    when "memo"    then "yellow"
    else "gray"
    end
  end
end
