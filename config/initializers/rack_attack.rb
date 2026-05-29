# Rack::Attack によるレート制限設定
# ブルートフォース攻撃・スパム送信を防ぐ

class Rack::Attack
  # キャッシュストアにRailsのキャッシュを直接使用
  Rack::Attack.cache.store = Rails.cache

  # ===== ログイン試行をIPアドレスで制限 =====
  # 同一IPから5分間に10回を超えるログイン試行をブロック
  throttle("login/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  # ===== パスワードリセットをメールアドレスで制限 =====
  # 同一メールに5分間に1回までに制限（存在しないメールでも同様に制限）
  throttle("password_reset/email", limit: 1, period: 5.minutes) do |req|
    if req.path == "/users/password" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # ===== パスワードリセットをIPで制限 =====
  # 同一IPから5分間に5回まで（メールアドレス収集攻撃の対策）
  throttle("password_reset/ip", limit: 5, period: 5.minutes) do |req|
    req.ip if req.path == "/users/password" && req.post?
  end

  # ===== 制限超過時のレスポンス =====
  throttled_responder = lambda do |req|
    retry_after = (req.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "text/html; charset=utf-8",
        "Retry-After"  => retry_after.to_s
      },
      [<<~HTML]
        <!DOCTYPE html>
        <html lang="ja">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>アクセスが制限されています</title>
          <style>
            body { font-family: sans-serif; text-align: center; padding: 60px 20px; background: #f5f0e8; }
            h1 { color: #2c4f7c; }
            p  { color: #5a5a5a; }
            a  { color: #2a7f6f; }
          </style>
        </head>
        <body>
          <h1>⚠️ アクセスが一時的に制限されています</h1>
          <p>短時間に多くのリクエストが検出されました。<br>
             しばらく（約5分）待ってから再度お試しください。</p>
          <p><a href="/">トップページに戻る</a></p>
        </body>
        </html>
      HTML
    ]
  end

  self.throttled_responder = throttled_responder
end
