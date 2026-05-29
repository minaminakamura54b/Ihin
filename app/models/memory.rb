class Memory < ApplicationRecord
  belongs_to :user
  belongs_to :item, optional: true
  has_one_attached :photo
  has_many :album_memories, dependent: :destroy
  has_many :albums, through: :album_memories

  validates :user, presence: true
  validates :title, length: { maximum: 100 }
  validates :description, length: { maximum: 2000 }, allow_blank: true

  before_create :generate_share_token

  scope :shared, -> { where(shared: true) }

  def display_title
    title.presence || item&.name.presence || "思い出"
  end

  validate :validate_photo, if: -> { photo.attached? }

  private

  def generate_share_token
    self.share_token = SecureRandom.urlsafe_base64(12)
  end

  def validate_photo
    unless photo.content_type.start_with?("image/")
      errors.add(:photo, "は画像ファイル（JPEG・PNG・WebP等）を選択してください")
    end
    if photo.byte_size > 20.megabytes
      errors.add(:photo, "は20MB以内にしてください")
    end
  end
end
