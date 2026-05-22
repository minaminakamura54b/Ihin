class Stripe::WebhooksController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    begin
      event = ::Stripe::Webhook.construct_event(payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"])
    rescue ::Stripe::SignatureVerificationError
      return head :bad_request
    end

    case event["type"]
    when "customer.subscription.updated"
      handle_subscription_updated(event["data"]["object"])
    when "customer.subscription.deleted"
      handle_subscription_deleted(event["data"]["object"])
    when "invoice.payment_succeeded"
      handle_payment_succeeded(event["data"]["object"])
    when "invoice.payment_failed"
      handle_payment_failed(event["data"]["object"])
    end

    head :ok
  end

  private

  def handle_subscription_updated(subscription)
    business = Business.find_by(stripe_subscription_id: subscription["id"])
    return unless business

    business.update(active: subscription["status"] == "active")
  end

  def handle_subscription_deleted(subscription)
    business = Business.find_by(stripe_subscription_id: subscription["id"])
    return unless business

    business.update(active: false, stripe_subscription_id: nil)
  end

  def handle_payment_succeeded(invoice)
    # 支払い成功時の処理（必要に応じてメール送信など）
  end

  def handle_payment_failed(invoice)
    # 支払い失敗時の処理
    business = Business.find_by(stripe_customer_id: invoice["customer"])
    business&.update(active: false)
  end
end
