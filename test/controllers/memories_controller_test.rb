require "test_helper"

class MemoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  # ===== 認証チェック =====

  test "未ログインで index にアクセスするとリダイレクト" do
    sign_out @user
    get memories_path
    assert_redirected_to new_user_session_path
  end

  test "未ログインで new にアクセスするとリダイレクト" do
    sign_out @user
    get new_memory_path
    assert_redirected_to new_user_session_path
  end

  test "未ログインで create するとリダイレクト" do
    sign_out @user
    assert_no_difference "Memory.count" do
      post memories_path, params: { memory: { comment: "テスト" } }
    end
    assert_redirected_to new_user_session_path
  end

  # ===== index =====

  test "index が 200 を返す" do
    3.times { create(:memory, user: @user) }
    get memories_path
    assert_response :success
  end

  test "index は自分の思い出のみ返す" do
    my_memory    = create(:memory, user: @user,       comment: "自分の思い出")
    other_memory = create(:memory, user: create(:user), comment: "他人の思い出")
    get memories_path
    assert_response :success
    assert_includes response.body, "自分の思い出"
    assert_not_includes response.body, "他人の思い出"
  end

  # ===== new =====

  test "new が 200 を返す" do
    get new_memory_path
    assert_response :success
  end

  test "new に item_id を渡すとフォームに反映される" do
    item = create(:item, user: @user)
    get new_memory_path, params: { item_id: item.id }
    assert_response :success
    assert_select "input[name='memory[item_id]'][value='#{item.id}']"
  end

  # ===== create =====

  test "コメントのみで create すると memories_path にリダイレクト" do
    assert_difference "Memory.count", 1 do
      post memories_path, params: { memory: { comment: "大切な思い出" } }
    end
    assert_redirected_to memories_path
    assert_equal "思い出を保存しました", flash[:notice]
  end

  test "create 後のレコードは current_user に紐づく" do
    post memories_path, params: { memory: { comment: "私の思い出" } }
    assert_equal @user, Memory.last.user
  end

  test "item_id 付きで create できる" do
    item = create(:item, user: @user)
    assert_difference "Memory.count", 1 do
      post memories_path, params: { memory: { comment: "品物の思い出", item_id: item.id } }
    end
    assert_equal item, Memory.last.item
  end

  # ===== show =====

  test "自分の memory を show できる" do
    memory = create(:memory, user: @user)
    get memory_path(memory)
    assert_response :success
  end

  test "他ユーザーの memory を show すると 404" do
    other_memory = create(:memory, user: create(:user))
    get memory_path(other_memory)
    assert_response :not_found
  end

  # ===== edit / update =====

  test "自分の memory を edit できる" do
    memory = create(:memory, user: @user)
    get edit_memory_path(memory)
    assert_response :success
  end

  test "他ユーザーの memory を edit すると 404" do
    other_memory = create(:memory, user: create(:user))
    get edit_memory_path(other_memory)
    assert_response :not_found
  end

  test "update が comment を更新して show にリダイレクト" do
    memory = create(:memory, user: @user, comment: "元のコメント")
    patch memory_path(memory), params: { memory: { comment: "更新後コメント" } }
    assert_redirected_to memory_path(memory)
    assert_equal "更新後コメント", memory.reload.comment
  end

  test "他ユーザーの memory を update すると 404" do
    other_memory = create(:memory, user: create(:user), comment: "元")
    patch memory_path(other_memory), params: { memory: { comment: "改ざん" } }
    assert_response :not_found
    assert_equal "元", other_memory.reload.comment
  end

  # ===== destroy =====

  test "destroy が memory を削除して memories_path にリダイレクト" do
    memory = create(:memory, user: @user)
    assert_difference "Memory.count", -1 do
      delete memory_path(memory)
    end
    assert_redirected_to memories_path
  end

  test "他ユーザーの memory を destroy すると 404" do
    other_memory = create(:memory, user: create(:user))
    assert_no_difference "Memory.count" do
      delete memory_path(other_memory)
    end
    assert_response :not_found
  end
end
