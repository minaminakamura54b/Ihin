class CreateConsultations < ActiveRecord::Migration[8.1]
  def change
    create_table :consultations do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message
      t.text :response

      t.timestamps
    end
  end
end
