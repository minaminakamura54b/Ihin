class BulkAssessmentItem < ApplicationRecord
  belongs_to :bulk_assessment
  has_many_attached :photos

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  VALID_ACTIONS = %w[sell keep dispose].freeze

  def display_name
    name.presence || "遺品"
  end

  def action_label
    case suggested_action
    when "sell"    then "売る"
    when "keep"    then "残す"
    when "dispose" then "処分する"
    end
  end
end
