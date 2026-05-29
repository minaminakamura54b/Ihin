class Album < ApplicationRecord
  belongs_to :user
  has_many :album_memories, dependent: :destroy
  has_many :memories, through: :album_memories
  has_one_attached :cover_image

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true

  before_create :generate_share_token

  scope :ordered, -> { order(created_at: :desc) }

  # アルバムのカバー写真（明示的に設定がなければ最初の思い出の写真を使う）
  def cover_photo
    return cover_image if cover_image.attached?
    memories.joins(:photo_attachment).first&.photo
  end

  # アルバム内の思い出数
  def memories_count
    memories.count
  end

  private

  def generate_share_token
    self.share_token = SecureRandom.urlsafe_base64(12)
  end
end
