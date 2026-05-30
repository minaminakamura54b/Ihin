class AddServicePrefecturesToBusinesses < ActiveRecord::Migration[8.1]
  def change
    # 対応都道府県を配列で保持（複数都道府県を選択可能）
    add_column :businesses, :service_prefectures, :text, array: true, default: []
    add_index  :businesses, :service_prefectures, using: :gin
  end
end
