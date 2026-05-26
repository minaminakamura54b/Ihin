class AddFieldsToMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :memories, :title,       :string
    add_column :memories, :description, :text
    add_column :memories, :ai_summary,  :text
    add_column :memories, :shared,      :boolean, default: false, null: false
    add_column :memories, :share_token, :string

    add_index :memories, :share_token, unique: true
  end
end
