class CreateDigitalItems < ActiveRecord::Migration[8.1]
  def change
    create_table :digital_items do |t|
      t.references :user,         null: false, foreign_key: true
      t.integer    :category,     null: false, default: 0
      t.string     :service_name, null: false
      t.integer    :status,       null: false, default: 0
      t.integer    :priority,     null: false, default: 2
      t.text       :notes

      t.timestamps
    end

    add_index :digital_items, [ :user_id, :category ]
    add_index :digital_items, [ :user_id, :status ]
  end
end
