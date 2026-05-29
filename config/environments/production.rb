require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Active Storage は S3 を使用（Render はエフェメラルストレージのためローカル保存不可）
  config.active_storage.service = :amazon

  # SSL終端はリバースプロキシ（Render）で行う
  config.assume_ssl = true

  # HTTPS強制・Strict-Transport-Security・セキュアCookie
  config.force_ssl = true

  # 本番環境のセッションCookie（secure属性追加でHTTPS通信のみ）
  # httponly: XSS対策  secure: 平文HTTP非送信  same_site: :strict CSRF対策
  config.session_store :cookie_store,
                       key:          "_ihin_session",
                       httponly:     true,
                       secure:       true,
                       same_site:    :strict,
                       expire_after: 90.days

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # シングルDBでSolid Queueを使用（別DBは不要）
  config.active_job.queue_adapter = :solid_queue

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "ihin-app.jp"), protocol: "https" }
  config.action_mailer.raise_delivery_errors = true

  # Resend によるメール送信（worknests.org ドメイン認証済み）
  config.action_mailer.delivery_method = :resend

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # DNS リバインディング攻撃対策：許可するホストを明示
  # APP_HOST 環境変数で本番ドメインを指定、Render の内部ドメインも許可
  app_host = ENV.fetch("APP_HOST", "ihin-app.jp")
  config.hosts = [
    app_host,
    /\A.+\.onrender\.com\z/  # Render のデプロイプレビュー URL
  ]
  # ヘルスチェックはホスト検証をスキップ（Render のヘルスチェックが通るように）
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
