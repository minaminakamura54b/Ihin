class AddItemToInquiries < ActiveRecord::Migration[8.1]
  def change
    add_reference :inquiries, :item, null: true, foreign_key: true
  end
end
