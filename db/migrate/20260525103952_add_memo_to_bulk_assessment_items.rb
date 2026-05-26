class AddMemoToBulkAssessmentItems < ActiveRecord::Migration[8.1]
  def change
    add_column :bulk_assessment_items, :memo, :text
  end
end
