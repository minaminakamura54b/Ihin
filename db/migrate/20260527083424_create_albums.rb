class CreateAlbums < ActiveRecord::Migration[8.1]
  def change
    create_table :albums do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :share_token
      t.boolean :shared, null: false, default: false
      t.text :ai_summary

      t.timestamps
    end
    add_index :albums, :share_token, unique: true
  end
end
