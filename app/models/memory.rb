class Memory < ApplicationRecord
  belongs_to :user
  belongs_to :item, optional: true
  has_one_attached :photo

  validates :user, presence: true
end
