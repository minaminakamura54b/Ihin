class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.decimal :estimated_price, precision: 10, scale: 0
      t.integer :action, default: 0
      t.text :ai_result
      t.text :memo
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
