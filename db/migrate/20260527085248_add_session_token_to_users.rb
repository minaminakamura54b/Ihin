class AddSessionTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :session_token, :string
    add_column :users, :password_changed_at, :datetime
    add_index :users, :session_token, unique: true
    # 既存ユーザーにセッショントークンを付与
    reversible do |dir|
      dir.up { User.find_each { |u| u.update_column(:session_token, SecureRandom.hex(32)) } }
    end
  end
end
