require "test_helper"

class UserRegistrationTest < ActionDispatch::IntegrationTest
  # ===== family ユーザー登録 =====

  test "family ユーザーが登録するとTodoItemが自動生成されてrootにリダイレクト" do
    assert_difference "User.count", 1 do
      assert_difference "TodoItem.count", 46 do
        post user_registration_path, params: {
          user: {
            name: "田中 花子",
            email: "hanako@example.com",
            password: "password123",
            password_confirmation: "password123",
            role: "family"
          }
        }
      end
    end
    assert_redirected_to root_path
    user = User.find_by(email: "hanako@example.com")
    assert user.family?
    assert_equal 46, user.todo_items.count
  end

  test "family ユーザー登録時に Business は作成されない" do
    assert_no_difference "Business.count" do
      post user_registration_path, params: {
        user: {
          name: "テストユーザー",
          email: "test_family@example.com",
          password: "password123",
          password_confirmation: "password123",
          role: "family"
        }
      }
    end
  end

  # ===== business ユーザー登録 =====

  test "business ユーザーが登録すると審査待ち状態の Business が作成されて email_sent にリダイレクト" do
    assert_difference "User.count", 1 do
      assert_difference "Business.count", 1 do
        post user_registration_path, params: {
          user: {
            name: "山田 業者",
            email: "yamada_biz@example.com",
            password: "password123",
            password_confirmation: "password123",
            role: "business"
          }
        }
      end
    end
    user = User.find_by(email: "yamada_biz@example.com")
    assert user.business?
    assert_not_nil user.business
    assert user.business.free?
    # 新規登録は審査待ち・非公開状態
    assert user.business.pending?
    assert_not user.business.active?
    assert_redirected_to email_sent_businesses_path
  end

  test "business ユーザー登録時に TodoItem は作成されない" do
    assert_no_difference "TodoItem.count" do
      post user_registration_path, params: {
        user: {
          name: "業者ユーザー",
          email: "biz_notodo@example.com",
          password: "password123",
          password_confirmation: "password123",
          role: "business"
        }
      }
    end
  end

  # ===== バリデーションエラー =====

  test "name が空の場合は登録に失敗する" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        user: {
          name: "",
          email: "noname@example.com",
          password: "password123",
          password_confirmation: "password123",
          role: "family"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
