require "test_helper"

class BusinessMatchingTest < ActiveSupport::TestCase
  # ===== BusinessMatcher.find_for =====

  test "user が nil の場合はエリアフィルターなしで全業者を返す（最大3社）" do
    create(:business, area: "東京都", plan: :free)
    create(:business, :premium_plan, area: "大阪府")
    create(:business, :standard_plan, area: "神奈川県横浜市")

    result = BusinessMatcher.find_for(nil)
    assert result.count <= BusinessMatcher::MAX_BUSINESSES
  end

  test "ユーザーの都道府県にマッチする業者のみ返す" do
    tokyo_user = create(:user, prefecture: "東京都")
    tokyo_biz  = create(:business, area: "東京都・神奈川県")
    osaka_biz  = create(:business, area: "大阪府")

    result = BusinessMatcher.find_for(tokyo_user)
    assert_includes result, tokyo_biz
    assert_not_includes result, osaka_biz
  end

  test "prefecture が nil の場合はエリアフィルターをスキップする" do
    user = create(:user, prefecture: nil)
    biz1 = create(:business, area: "東京都")
    biz2 = create(:business, area: "大阪府")

    result = BusinessMatcher.find_for(user)
    assert_includes result, biz1
    assert_includes result, biz2
  end

  test "カテゴリでフィルターできる" do
    user = create(:user)
    estate_biz   = create(:business, category: :estate_clearance, area: "全国")
    buyback_biz  = create(:business, category: :buyback, area: "全国")

    result = BusinessMatcher.find_for(user, category: :estate_clearance)
    assert_includes result, estate_biz
    assert_not_includes result, buyback_biz
  end

  test "最大3社に絞られる" do
    user = create(:user)
    4.times { create(:business, area: "全国") }

    result = BusinessMatcher.find_for(user)
    assert result.count <= BusinessMatcher::MAX_BUSINESSES
  end

  test "プレミアム業者が先頭に来る（プラン順）" do
    user = create(:user)
    free_biz     = create(:business,               area: "全国")
    premium_biz  = create(:business, :premium_plan, area: "全国")
    standard_biz = create(:business, :standard_plan, area: "全国")

    result = BusinessMatcher.find_for(user)
    # premium が free より前に来ることを確認
    premium_idx  = result.to_a.index(premium_biz)
    free_idx     = result.to_a.index(free_biz)
    assert_not_nil premium_idx
    assert_not_nil free_idx
    assert premium_idx < free_idx, "premium がfreeより先に来るべき"
  end

  test "inactive な業者は結果に含まれない" do
    user = create(:user)
    active_biz   = create(:business, area: "全国")
    inactive_biz = create(:business, :inactive, area: "全国")

    result = BusinessMatcher.find_for(user)
    assert_includes result, active_biz
    assert_not_includes result, inactive_biz
  end
end
