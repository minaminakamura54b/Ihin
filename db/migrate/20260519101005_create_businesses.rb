class CreateBusinesses < ActiveRecord::Migration[8.1]
  def change
    create_table :businesses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :category, default: 0
      t.string :area
      t.integer :plan, default: 0
      t.string :stripe_subscription_id
      t.string :stripe_customer_id
      t.boolean :active, default: false, null: false
      t.text :description
      t.string :phone
      t.string :website

      t.timestamps
    end
  end
end
