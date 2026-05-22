class CreateBulkAssessments < ActiveRecord::Migration[8.1]
  def change
    create_table :bulk_assessments do |t|
      t.references :user, null: true, foreign_key: true
      t.string :session_token
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :bulk_assessments, :session_token
  end
end
