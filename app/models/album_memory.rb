class AlbumMemory < ApplicationRecord
  belongs_to :album
  belongs_to :memory

  validates :album_id, uniqueness: { scope: :memory_id, message: "この思い出はすでにアルバムに追加されています" }

  default_scope { order(:position) }
end
