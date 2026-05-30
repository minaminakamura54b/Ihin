require "test_helper"

class InquiryTest < ActiveSupport::TestCase
  # ===== バリデーション =====

  test "message がない場合は無効" do
    inquiry = Inquiry.new(
      user: create(:user),
      business: create(:business),
      message: ""
    )
    assert_not inquiry.valid?
    assert inquiry.errors[:message].any?
  end

  test "user なしでは無効" do
    inquiry = Inquiry.new(
      business: create(:business),
      message: "問い合わせ"
    )
    assert_not inquiry.valid?
  end

  test "business なしでは無効" do
    inquiry = Inquiry.new(
      user: create(:user),
      message: "問い合わせ"
    )
    assert_not inquiry.valid?
  end

  # ===== item は optional =====

  test "item なしで作成できる" do
    inquiry = Inquiry.new(
      user: create(:user),
      business: create(:business),
      message: "問い合わせ",
      contact_type: :email,
      contact_info: "test@example.com"
    )
    assert inquiry.valid?
    assert_nil inquiry.item
  end

  test "item ありで作成できる" do
    family = create(:user)
    item    = create(:item, user: family)
    inquiry = Inquiry.new(
      user: family,
      business: create(:business),
      message: "この品物についての問い合わせです",
      contact_type: :email,
      contact_info: "test@example.com",
      item: item
    )
    assert inquiry.valid?
  end

  # ===== status enum =====

  test "status のデフォルトは pending" do
    inq = create(:inquiry)
    assert inq.pending?
  end

  test "status を contacted に変更できる" do
    inq = create(:inquiry)
    inq.contacted!
    assert inq.contacted?
  end

  test "status を closed に変更できる" do
    inq = create(:inquiry)
    inq.closed!
    assert inq.closed?
  end
end
