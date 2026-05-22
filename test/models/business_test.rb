require "test_helper"

class BusinessTest < ActiveSupport::TestCase
  # ===== バリデーション =====

  test "name がない場合は無効" do
    user = create(:user, :business_role)
    biz = user.business
    biz.name = ""
    assert_not biz.valid?
  end

  # ===== plan enum & contact_limit =====

  test "free plan の contact_limit は 2" do
    biz = create(:business)
    assert_equal 2, biz.contact_limit
  end

  test "basic plan の contact_limit は 10" do
    biz = create(:business, :basic_plan)
    assert_equal 10, biz.contact_limit
  end

  test "standard plan の contact_limit は 30" do
    biz = create(:business, :standard_plan)
    assert_equal 30, biz.contact_limit
  end

  test "premium plan の contact_limit は Float::INFINITY" do
    biz = create(:business, :premium_plan)
    assert_equal Float::INFINITY, biz.contact_limit
  end

  # ===== monthly_price =====

  test "monthly_price は free で 0 を返す" do
    biz = create(:business)
    assert_equal 0, biz.monthly_price
  end

  test "monthly_price は basic で 10000 を返す" do
    biz = create(:business, :basic_plan)
    assert_equal 10_000, biz.monthly_price
  end

  test "monthly_price は standard で 30000 を返す" do
    biz = create(:business, :standard_plan)
    assert_equal 30_000, biz.monthly_price
  end

  test "monthly_price は premium で 50000 を返す" do
    biz = create(:business, :premium_plan)
    assert_equal 50_000, biz.monthly_price
  end

  # ===== free_period_active? =====

  test "free_period_active? は作成直後 true" do
    biz = create(:business)
    assert biz.free_period_active?
  end

  test "free_period_active? は 91日後 false" do
    biz = create(:business)
    travel_to 91.days.from_now do
      assert_not biz.free_period_active?
    end
  end

  test "free_period_active? は free 以外のプランで false" do
    biz = create(:business, :basic_plan)
    assert_not biz.free_period_active?
  end

  # ===== scope =====

  test "active scope は active=true の Business のみ返す" do
    active_biz   = create(:business)
    inactive_biz = create(:business, :inactive)
    assert_includes Business.active, active_biz
    assert_not_includes Business.active, inactive_biz
  end

  # ===== plan_label =====

  test "plan_label は free で正しい文字列を返す" do
    biz = create(:business)
    assert_equal "無料プラン（3ヶ月限定）", biz.plan_label
  end

  test "plan_label は basic で正しい文字列を返す" do
    biz = create(:business, :basic_plan)
    assert_equal "ベーシック（月額1万円）", biz.plan_label
  end

  test "plan_label は premium で正しい文字列を返す" do
    biz = create(:business, :premium_plan)
    assert_equal "プレミアム（月額5万円）", biz.plan_label
  end

  # ===== category_label =====

  test "category_label は estate_clearance で '遺品整理業者' を返す" do
    biz = create(:business)
    assert_equal "遺品整理業者", biz.category_label
  end

  test "category_label は buyback で '買取業者' を返す" do
    biz = create(:business)
    biz.update!(category: :buyback)
    assert_equal "買取業者", biz.category_label
  end

  # ===== can_contact? =====

  test "can_contact? は今月の問い合わせが limit 未満の場合 true" do
    biz = create(:business)
    assert biz.can_contact?
  end

  test "can_contact? は今月の問い合わせが limit に達した場合 false" do
    biz = create(:business)  # free plan: limit 2
    user = create(:user)
    2.times { create(:inquiry, business: biz, user: user) }
    assert_not biz.can_contact?
  end
end
