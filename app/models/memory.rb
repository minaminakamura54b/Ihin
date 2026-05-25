class Memory < ApplicationRecord
  belongs_to :user
  belongs_to :item, optional: true
  has_one_attached :photo

  validates :user, presence: true
  validate :validate_photo, if: -> { photo.attached? }

  private

  def validate_photo
    unless photo.content_type.start_with?("image/")
      errors.add(:photo, "は画像ファイル（JPEG・PNG・WebP等）を選択してください")
    end
    if photo.byte_size > 20.megabytes
      errors.add(:photo, "は20MB以内にしてください")
    end
  end
end
