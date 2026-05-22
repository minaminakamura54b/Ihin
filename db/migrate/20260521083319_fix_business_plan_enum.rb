class FixBusinessPlanEnum < ActiveRecord::Migration[8.1]
  def up
    # 既存データを新しい値にずらす（大きい値から順に更新して衝突を防ぐ）
    execute "UPDATE businesses SET plan = 3 WHERE plan = 2"
    execute "UPDATE businesses SET plan = 2 WHERE plan = 1"
    execute "UPDATE businesses SET plan = 1 WHERE plan = 0"
  end

  def down
    execute "UPDATE businesses SET plan = 0 WHERE plan = 1"
    execute "UPDATE businesses SET plan = 1 WHERE plan = 2"
    execute "UPDATE businesses SET plan = 2 WHERE plan = 3"
  end
end
