require "test_helper"

class BusinessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner       = create(:user, :business_role)
    @business    = @owner.business
    # テスト用に承認済み状態にしておく（本番は管理者が手動承認）
    @business.update!(approval_status: :approved, active: true)
    @family_user = create(:user)
  end

  # ===== index (認証不要) =====

  test "index は未ログインでも 200" do
    get businesses_path
    assert_response :success
  end

  test "index はログイン済みでも 200" do
    sign_in @family_user
    get businesses_path
    assert_response :success
  end

  # ===== show (認証不要) =====

  test "show は未ログインでも 200" do
    get business_path(@business)
    assert_response :success
  end

  # ===== dashboard =====

  test "dashboard はオーナー本人がアクセスできる" do
    sign_in @owner
    get dashboard_business_path(@business)
    assert_response :success
  end

  test "dashboard は family ユーザーがアクセスするとリダイレクト" do
    sign_in @family_user
    get dashboard_business_path(@business)
    assert_redirected_to root_path
    assert_equal "業者アカウントでログインしてください", flash[:alert]
  end

  test "dashboard は別の業者がアクセスするとリダイレクト" do
    other_biz_user = create(:user, :business_role)
    other_biz_user.business.update!(approval_status: :approved, active: true)
    sign_in other_biz_user
    get dashboard_business_path(@business)
    assert_redirected_to root_path
    assert_equal "権限がありません", flash[:alert]
  end

  test "未ログインで dashboard にアクセスするとログインページへ" do
    get dashboard_business_path(@business)
    assert_redirected_to new_user_session_path
  end

  # ===== edit =====

  test "edit はオーナー本人がアクセスできる" do
    sign_in @owner
    get edit_business_path(@business)
    assert_response :success
  end

  test "edit は他ユーザーがアクセスするとリダイレクト" do
    sign_in @family_user
    get edit_business_path(@business)
    assert_redirected_to root_path
    assert_equal "権限がありません", flash[:alert]
  end

  # ===== update =====

  test "update はオーナーが実行できる" do
    sign_in @owner
    patch business_path(@business), params: { business: { name: "新しい会社名" } }
    assert_redirected_to business_path(@business)
    assert_equal "新しい会社名", @business.reload.name
  end

  test "update は他ユーザーが実行するとリダイレクト" do
    sign_in @family_user
    original_name = @business.name
    patch business_path(@business), params: { business: { name: "hack" } }
    assert_redirected_to root_path
    assert_equal original_name, @business.reload.name
  end

  # ===== service_prefectures 更新 =====

  test "オーナーが service_prefectures を更新できる" do
    sign_in @owner
    patch business_path(@business), params: {
      business: { service_prefectures: %w[大阪府 京都府] }
    }
    assert_redirected_to business_path(@business)
    assert_equal %w[大阪府 京都府], @business.reload.service_prefectures
  end

  test "service_prefectures の空文字列はフォーム送信時に除去される" do
    sign_in @owner
    patch business_path(@business), params: {
      business: { service_prefectures: [ "", "埼玉県", "" ] }
    }
    assert_equal %w[埼玉県], @business.reload.service_prefectures
  end

  test "他ユーザーは service_prefectures を更新できない（認可テスト）" do
    sign_in @family_user
    original = @business.service_prefectures.dup
    patch business_path(@business), params: {
      business: { service_prefectures: %w[沖縄県] }
    }
    assert_redirected_to root_path
    assert_equal original, @business.reload.service_prefectures
  end

  test "未ログインは service_prefectures を更新できない" do
    patch business_path(@business), params: {
      business: { service_prefectures: %w[沖縄県] }
    }
    assert_redirected_to new_user_session_path
    assert_not_equal %w[沖縄県], @business.reload.service_prefectures
  end

  # ===== セキュリティ: マスアサインメント =====

  test "role は business_params 経由で変更できない" do
    sign_in @owner
    patch business_path(@business), params: {
      business: { name: "test", role: "admin" }
    }
    # User の role は変化しない（Business モデルに role はない → 無視される）
    assert_equal "business", @owner.reload.role
  end

  test "approval_status はオーナーが変更できない（管理者専用）" do
    sign_in @owner
    patch business_path(@business), params: {
      business: { approval_status: "rejected" }
    }
    assert_equal "approved", @business.reload.approval_status
  end

  # ===== service_prefectures による検索（index）=====

  test "都道府県検索で service_prefectures にマッチする業者が返る" do
    @business.update!(service_prefectures: %w[神奈川県])
    get businesses_path, params: { prefecture: "神奈川県" }
    assert_response :success
    assert_select "turbo-frame#businesses-list"
  end

  test "都道府県未選択では業者一覧は表示されない" do
    get businesses_path
    assert_response :success
    # リスト内に biz-map-guide（未選択ガイド）が表示される
    assert_select ".biz-map-guide"
  end

  test "prefecture パラメータに不正値を渡しても 500 にならない" do
    # SQL インジェクション試行（? = ANY(service_prefectures) は parameterized なので安全）
    get businesses_path, params: { prefecture: "'; DROP TABLE businesses; --" }
    assert_response :success
  end

  # ===== subscribe (Stripe モック) =====

  test "subscribe が free→free の場合 alert でリダイレクト" do
    sign_in @owner
    post subscribe_business_path(@business), params: { plan: "free" }
    assert_redirected_to dashboard_business_path(@business)
    assert_equal "すでに無料プランです", flash[:alert]
  end

  test "subscribe が成功してプランを変更する" do
    sign_in @owner
    StripeSubscriptionService.any_instance.stubs(:create_subscription).returns({ success: true })
    post subscribe_business_path(@business), params: { plan: "basic" }
    assert_redirected_to dashboard_business_path(@business)
    assert @business.reload.basic?
  end

  test "subscribe が失敗した場合 alert でリダイレクト" do
    sign_in @owner
    StripeSubscriptionService.any_instance.stubs(:create_subscription).returns({
      success: false, error: "カード決済エラー"
    })
    post subscribe_business_path(@business), params: { plan: "basic" }
    assert_redirected_to dashboard_business_path(@business)
    assert_match "カード決済エラー", flash[:alert]
  end

  # ===== unsubscribe =====

  test "unsubscribe が成功する" do
    sign_in @owner
    @business.update!(stripe_subscription_id: "sub_test123")
    StripeSubscriptionService.any_instance.stubs(:cancel_subscription).returns({ success: true })
    delete unsubscribe_business_path(@business)
    assert_redirected_to business_path(@business)
  end

  # ===== destroy =====

  test "destroy はオーナーが Business を削除できる" do
    sign_in @owner
    assert_difference "Business.count", -1 do
      delete business_path(@business)
    end
    assert_redirected_to root_path
  end

  test "destroy は他ユーザーが実行するとリダイレクト" do
    sign_in @family_user
    assert_no_difference "Business.count" do
      delete business_path(@business)
    end
    assert_redirected_to root_path
  end
end
