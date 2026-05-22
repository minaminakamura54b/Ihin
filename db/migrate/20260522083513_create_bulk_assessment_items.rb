class CreateBulkAssessmentItems < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_assessment_items do |t|
      t.references :bulk_assessment, null: false, foreign_key: true
      t.string :name
      t.integer :position, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.text :ai_result
      t.integer :estimated_price
      t.string :suggested_action
      t.text :error_message

      t.timestamps
    end

    add_index :bulk_assessment_items, [ :bulk_assessment_id, :position ]
  end
end
