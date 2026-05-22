require "test_helper"

class TodoItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :admin)  # admin は auto-generate コールバックがない
    sign_in @user
  end

  # ===== 認証チェック =====

  test "未ログインで index にアクセスするとリダイレクト" do
    sign_out @user
    get todo_items_path
    assert_redirected_to new_user_session_path
  end

  # ===== index =====

  test "index が 200 を返す" do
    get todo_items_path
    assert_response :success
  end

  # ===== create =====

  test "有効なパラメータで create すると TodoItem が追加される" do
    assert_difference "TodoItem.count", 1 do
      post todo_items_path, params: {
        todo_item: { title: "新しいタスク", category: "normal", priority: 1 }
      }
    end
    assert_redirected_to todo_items_path
  end

  test "title が空の場合 create は失敗する" do
    assert_no_difference "TodoItem.count" do
      post todo_items_path, params: {
        todo_item: { title: "", category: "normal", priority: 1 }
      }
    end
    assert_response :unprocessable_entity
  end

  # ===== toggle =====

  test "toggle で completed が false から true に反転する" do
    todo = create(:todo_item, user: @user, completed: false)
    patch toggle_todo_item_path(todo)
    assert todo.reload.completed
  end

  test "toggle で completed が true から false に反転する" do
    todo = create(:todo_item, user: @user, completed: true)
    patch toggle_todo_item_path(todo)
    assert_not todo.reload.completed
  end

  test "他ユーザーの todo_item は toggle で 404" do
    other = create(:user, :admin)
    other_todo = create(:todo_item, user: other)
    patch toggle_todo_item_path(other_todo)
    assert_response :not_found
  end

  # ===== destroy =====

  test "destroy が todo_item を削除する" do
    todo = create(:todo_item, user: @user)
    assert_difference "TodoItem.count", -1 do
      delete todo_item_path(todo)
    end
    assert_redirected_to todo_items_path
  end

  test "他ユーザーの todo_item は destroy で 404" do
    other = create(:user, :admin)
    other_todo = create(:todo_item, user: other)
    delete todo_item_path(other_todo)
    assert_response :not_found
  end

  # ===== update =====

  test "update が todo_item を更新する" do
    todo = create(:todo_item, user: @user)
    patch todo_item_path(todo), params: {
      todo_item: { title: "更新後タスク", category: "urgent", priority: 1 }
    }
    assert_redirected_to todo_items_path
    assert_equal "更新後タスク", todo.reload.title
  end
end
