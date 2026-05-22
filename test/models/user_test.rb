require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ===== バリデーション =====

  test "name がない場合は無効" do
    user = User.new(email: "test@example.com", password: "password123", role: :family)
    assert_not user.valid?
    assert user.errors[:name].any?
  end

  test "email が重複している場合は無効" do
    create(:user, email: "dup@example.com")
    user = User.new(name: "重複ユーザー", email: "dup@example.com", password: "password123")
    assert_not user.valid?
  end

  test "有効な属性で family ユーザーを作成できる" do
    user = build(:user)
    assert user.valid?
  end

  # ===== role enum =====

  test "family role が正しく設定される" do
    user = create(:user, role: :family)
    assert user.family?
    assert_not user.business?
    assert_not user.admin?
  end

  test "business role が正しく設定される" do
    user = create(:user, :business_role)
    assert user.business?
    assert_not user.family?
  end

  test "admin role が正しく設定される" do
    user = create(:user, :admin)
    assert user.admin?
    assert_not user.family?
  end

  # ===== after_create コールバック =====

  test "family ユーザー作成時に 46件の TodoItem が生成される" do
    assert_difference "TodoItem.count", 46 do
      create(:user, role: :family)
    end
  end

  test "family ユーザーの TodoItem は TEMPLATES の内容と一致する" do
    user = create(:user, role: :family)
    assert_equal 46, user.todo_items.count
    assert user.todo_items.exists?(title: "死亡診断書を受け取り、コピーを10枚以上取る")
  end

  test "business ユーザー作成時に Business が 1件 自動生成される" do
    assert_difference "Business.count", 1 do
      create(:user, :business_role)
    end
  end

  test "business ユーザー作成時の Business は無料プランで active" do
    user = create(:user, :business_role)
    assert_not_nil user.business
    assert user.business.free?
    assert user.business.active?
    assert_equal "#{user.name}の会社", user.business.name
  end

  test "admin ユーザー作成時に TodoItem も Business も生成されない" do
    assert_no_difference [ "TodoItem.count", "Business.count" ] do
      create(:user, :admin)
    end
  end

  test "business ユーザー作成時に TodoItem は生成されない" do
    assert_no_difference "TodoItem.count" do
      create(:user, :business_role)
    end
  end

  # ===== business_user? =====

  test "business_user? は business role かつ active な Business がある場合 true" do
    user = create(:user, :business_role)
    assert user.business_user?
  end

  test "business_user? は family role の場合 false" do
    user = create(:user)
    assert_not user.business_user?
  end

  test "business_user? は Business が inactive の場合 false" do
    user = create(:user, :business_role)
    user.business.update!(active: false)
    assert_not user.business_user?
  end
end
