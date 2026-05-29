require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ihin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [ :ja, :en ]

    config.autoload_paths << Rails.root.join("app/services")

    # セッションCookieの設定（全環境共通）
    # httponly: true  → JS（XSS）からCookieを盗めなくする
    # same_site: :strict → 他サイトからのリクエストには一切Cookieを送信しない（CSRF対策）
    # expire_after: 90日間アクセスがなければCookieを失効
    config.session_store :cookie_store,
                         key:          "_ihin_session",
                         httponly:     true,
                         same_site:    :strict,
                         expire_after: 90.days

    # Rack::Attack をミドルウェアに追加
    config.middleware.use Rack::Attack
  end
end
