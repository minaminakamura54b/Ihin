class AddAddressToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :prefecture, :string
    add_column :users, :city, :string
  end
end
