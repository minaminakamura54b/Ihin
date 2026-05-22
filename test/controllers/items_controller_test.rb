require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = create(:user)
    @other = create(:user)
    @item  = create(:item, user: @user)
    sign_in @user
  end

  # ===== 認証チェック =====

  test "未ログインで index にアクセスするとリダイレクト" do
    sign_out @user
    get items_path
    assert_redirected_to new_user_session_path
  end

  test "未ログインで show にアクセスするとリダイレクト" do
    sign_out @user
    get item_path(@item)
    assert_redirected_to new_user_session_path
  end

  # ===== index =====

  test "index が 200 を返す" do
    get items_path
    assert_response :success
  end

  # ===== show =====

  test "show が 200 を返す" do
    get item_path(@item)
    assert_response :success
  end

  test "他ユーザーの item は show で 404" do
    other_item = create(:item, user: @other)
    get item_path(other_item)
    assert_response :not_found
  end

  # ===== create =====

  test "有効なパラメータで create すると item が作成される" do
    assert_difference "Item.count", 1 do
      post items_path, params: { item: { name: "時計", memo: "祖父の形見" } }
    end
    assert_redirected_to item_path(Item.last)
  end

  # ===== update =====

  test "update が成功する" do
    patch item_path(@item), params: { item: { name: "更新後の名前" } }
    assert_redirected_to item_path(@item)
    assert_equal "更新後の名前", @item.reload.name
  end

  test "他ユーザーの item は update で 404" do
    other_item = create(:item, user: @other)
    patch item_path(other_item), params: { item: { name: "hack" } }
    assert_response :not_found
  end

  # ===== destroy =====

  test "destroy が item を削除して items_path にリダイレクト" do
    assert_difference "Item.count", -1 do
      delete item_path(@item)
    end
    assert_redirected_to items_path
  end

  test "他ユーザーの item は destroy で 404" do
    other_item = create(:item, user: @other)
    delete item_path(other_item)
    assert_response :not_found
  end

  # ===== assess (AI モック) =====

  test "assess が成功する場合 ai_result を更新してリダイレクト" do
    AiAssessmentService.any_instance.stubs(:assess).returns({
      success: true,
      ai_result: "査定結果テキスト",
      estimated_price: 50_000,
      suggested_action: "sell",
      item_name: "テスト品"
    })
    post assess_item_path(@item)
    assert_redirected_to item_path(@item)
    assert_equal "査定結果テキスト", @item.reload.ai_result
    assert_equal 50_000, @item.reload.estimated_price.to_i
  end

  test "assess が失敗する場合 alert でリダイレクト" do
    AiAssessmentService.any_instance.stubs(:assess).returns({
      success: false,
      error: "API接続エラー"
    })
    post assess_item_path(@item)
    assert_redirected_to item_path(@item)
    assert_match "API接続エラー", flash[:alert]
  end

  test "他ユーザーの item は assess で 404" do
    other_item = create(:item, user: @other)
    post assess_item_path(other_item)
    assert_response :not_found
  end

  # ===== update_action =====

  test "update_action で action が sell に更新される" do
    patch update_action_item_path(@item), params: { action_type: "sell" }
    assert_redirected_to item_path(@item)
    assert @item.reload.sell?
  end

  test "update_action で action が keep に更新される" do
    patch update_action_item_path(@item), params: { action_type: "keep" }
    assert_redirected_to item_path(@item)
    assert @item.reload.keep?
  end

  test "他ユーザーの item は update_action で 404" do
    other_item = create(:item, user: @other)
    patch update_action_item_path(other_item), params: { action_type: "sell" }
    assert_response :not_found
  end
end
