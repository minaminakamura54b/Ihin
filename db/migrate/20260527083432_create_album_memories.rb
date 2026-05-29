class CreateAlbumMemories < ActiveRecord::Migration[8.1]
  def change
    create_table :album_memories do |t|
      t.references :album, null: false, foreign_key: true
      t.references :memory, null: false, foreign_key: true
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    # 同一アルバムに同じ思い出を重複登録しない
    add_index :album_memories, [ :album_id, :memory_id ], unique: true
  end
end
