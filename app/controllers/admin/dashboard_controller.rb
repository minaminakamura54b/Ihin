class Admin::DashboardController < Admin::BaseController
  def index
    @user_count = User.count
    @family_count = User.family.count
    @business_count = User.business.count
    @item_count = Item.count
    @active_businesses = Business.active.count
    @recent_inquiries = Inquiry.includes(:user, :business).order(created_at: :desc).limit(10)
  end
end
