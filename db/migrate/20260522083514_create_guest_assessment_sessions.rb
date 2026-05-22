class CreateGuestAssessmentSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :guest_assessment_sessions do |t|
      t.string :token, null: false
      t.integer :assessed_count, null: false, default: 0

      t.timestamps
    end

    add_index :guest_assessment_sessions, :token, unique: true
  end
end
