class PasswordHistory < ApplicationRecord
  belongs_to :user

  validates :encrypted_password, presence: true
end
