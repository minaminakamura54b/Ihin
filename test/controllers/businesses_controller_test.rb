require "test_helper"

class BusinessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner       = create(:user, :business_role)
    @business    = @owner.business
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
