class MigrateItemImageToImages < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE active_storage_attachments
      SET name = 'images'
      WHERE name = 'image' AND record_type = 'Item'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE active_storage_attachments
      SET name = 'image'
      WHERE name = 'images' AND record_type = 'Item'
    SQL
  end
end
