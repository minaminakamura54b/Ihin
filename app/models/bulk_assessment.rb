class BulkAssessment < ApplicationRecord
  belongs_to :user, optional: true
  has_many :bulk_assessment_items, -> { order(:position) }, dependent: :destroy

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  def completed_count
    bulk_assessment_items.where(status: [ :completed, :failed ]).count
  end

  def total_count
    bulk_assessment_items.count
  end

  def total_estimated_price
    bulk_assessment_items.where(status: :completed).sum(:estimated_price)
  end

  def all_done?
    bulk_assessment_items.all? { |i| i.completed? || i.failed? }
  end
end
