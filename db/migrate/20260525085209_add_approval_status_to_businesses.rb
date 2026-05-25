class AddApprovalStatusToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :approval_status, :integer, default: 0, null: false
    add_column :businesses, :rejected_reason, :text
    add_column :businesses, :license_number, :string
    add_index  :businesses, :approval_status

    # 既存の承認済み業者（active: true）はすべて approved に設定
    Business.reset_column_information
    Business.where(active: true).update_all(approval_status: 1)
  end
end
