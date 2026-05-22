require "test_helper"

class ItemTest < ActiveSupport::TestCase
  # ===== scope =====

  test "assessed scope は ai_result がある item のみ返す" do
    assessed = create(:item, :assessed)
    pending  = create(:item, :pending_assessment)
    assert_includes Item.assessed, assessed
    assert_not_includes Item.assessed, pending
  end

  test "pending_assessment scope は ai_result が nil の item のみ返す" do
    assessed = create(:item, :assessed)
    pending  = create(:item, :pending_assessment)
    assert_includes Item.pending_assessment, pending
    assert_not_includes Item.pending_assessment, assessed
  end

  # ===== assessed? =====

  test "assessed? は ai_result がある場合 true" do
    item = create(:item, :assessed)
    assert item.assessed?
  end

  test "assessed? は ai_result が nil の場合 false" do
    item = create(:item, :pending_assessment)
    assert_not item.assessed?
  end

  # ===== action_label =====

  test "action_label は undecided で '未分類' を返す" do
    item = build(:item, action: :undecided)
    assert_equal "未分類", item.action_label
  end

  test "action_label は sell で '売る' を返す" do
    item = build(:item, action: :sell)
    assert_equal "売る", item.action_label
  end

  test "action_label は keep で '残す' を返す" do
    item = build(:item, action: :keep)
    assert_equal "残す", item.action_label
  end

  test "action_label は dispose で '処分する' を返す" do
    item = build(:item, action: :dispose)
    assert_equal "処分する", item.action_label
  end

  test "action_label は memo で 'メモ' を返す" do
    item = build(:item, action: :memo)
    assert_equal "メモ", item.action_label
  end

  # ===== action_color =====

  test "action_color は sell で 'green' を返す" do
    item = build(:item, action: :sell)
    assert_equal "green", item.action_color
  end

  test "action_color は keep で 'blue' を返す" do
    item = build(:item, action: :keep)
    assert_equal "blue", item.action_color
  end

  test "action_color は dispose で 'red' を返す" do
    item = build(:item, action: :dispose)
    assert_equal "red", item.action_color
  end

  test "action_color は undecided で 'gray' を返す" do
    item = build(:item, action: :undecided)
    assert_equal "gray", item.action_color
  end

  # ===== バリデーション =====

  test "user なしでは無効" do
    item = Item.new(name: "テスト")
    assert_not item.valid?
  end
end
