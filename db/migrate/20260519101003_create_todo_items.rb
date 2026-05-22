class CreateTodoItems < ActiveRecord::Migration[8.1]
  def change
    create_table :todo_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :category, default: 0
      t.integer :priority, default: 1
      t.boolean :completed, default: false, null: false

      t.timestamps
    end
  end
end
