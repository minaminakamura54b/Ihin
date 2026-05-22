class CreateMemories < ActiveRecord::Migration[8.1]
  def change
    create_table :memories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true
      t.text :comment

      t.timestamps
    end
  end
end
