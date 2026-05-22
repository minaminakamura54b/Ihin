class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.text :message, null: false
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
