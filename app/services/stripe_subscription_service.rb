class StripeSubscriptionService
  PRICE_IDS = {
    "basic"    => ENV.fetch("STRIPE_PRICE_BASIC", "price_basic"),
    "standard" => ENV.fetch("STRIPE_PRICE_STANDARD", "price_standard"),
    "premium"  => ENV.fetch("STRIPE_PRICE_PREMIUM", "price_premium")
  }.freeze

  def initialize(user, business)
    @user = user
    @business = business
  end

  def create_subscription(plan)
    customer = find_or_create_customer
    price_id = PRICE_IDS[plan]

    subscription = Stripe::Subscription.create({
      customer: customer.id,
      items: [ { price: price_id } ],
      payment_behavior: "default_incomplete",
      payment_settings: { save_default_payment_method: "on_subscription" },
      expand: [ "latest_invoice.payment_intent" ]
    })

    @business.update(
      stripe_customer_id: customer.id,
      stripe_subscription_id: subscription.id,
      plan: plan,
      active: subscription.status == "active"
    )

    {
      success: true,
      subscription: subscription,
      client_secret: subscription.latest_invoice.payment_intent.client_secret
    }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  end

  def cancel_subscription
    return { success: false, error: "サブスクリプションが存在しません" } unless @business.stripe_subscription_id

    subscription = Stripe::Subscription.cancel(@business.stripe_subscription_id)
    @business.update(active: false, stripe_subscription_id: nil)

    { success: true, subscription: subscription }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  end

  private

  def find_or_create_customer
    if @business.stripe_customer_id.present?
      Stripe::Customer.retrieve(@business.stripe_customer_id)
    else
      Stripe::Customer.create({
        email: @user.email,
        name: @business.name,
        metadata: { user_id: @user.id, business_id: @business.id }
      })
    end
  end
end
