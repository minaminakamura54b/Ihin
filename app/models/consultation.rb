class Consultation < ApplicationRecord
  belongs_to :user
  validates :message, presence: true
  validates :response, presence: true
  scope :recent, -> { order(created_at: :desc) }
end
