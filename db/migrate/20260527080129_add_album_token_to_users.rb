class AddAlbumTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :album_token, :string
    add_index :users, :album_token, unique: true
    # 既存ユーザーにトークンを付与
    reversible do |dir|
      dir.up { User.find_each { |u| u.update_column(:album_token, SecureRandom.urlsafe_base64(16)) } }
    end
  end
end
