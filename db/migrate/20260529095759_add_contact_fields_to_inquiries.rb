class AddContactFieldsToInquiries < ActiveRecord::Migration[8.1]
  def change
    # 連絡方法（0: email, 1: phone）既存レコードはメールとして扱う
    add_column :inquiries, :contact_type, :integer, null: false, default: 0
    # 連絡先（メールアドレスまたは電話番号）
    add_column :inquiries, :contact_info, :string
  end
end
