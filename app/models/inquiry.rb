class Inquiry < ApplicationRecord
  belongs_to :user
  belongs_to :business
  belongs_to :item, optional: true

  enum :status, { pending: 0, contacted: 1, closed: 2 }

  validates :message, presence: true
end
