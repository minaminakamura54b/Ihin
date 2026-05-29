# サイトマップ設定
# 生成コマンド: bin/rails sitemap:refresh
# 本番環境では定期実行（例: Render の Cron Job で毎日）

SitemapGenerator::Sitemap.default_host = "https://#{ENV.fetch('APP_HOST', 'ihin-app.jp')}"

# 生成したsitemap.xmlの置き場所（public/ 直下）
SitemapGenerator::Sitemap.public_path = "public/"

# Googleへの自動通知を有効化
SitemapGenerator::Sitemap.create_index = true

SitemapGenerator::Sitemap.create do
  # ===== 公開ページ（ログイン不要） =====

  # トップ・LP
  add root_path,             changefreq: "weekly",  priority: 1.0

  # 業者一覧・検索
  add businesses_path,       changefreq: "daily",   priority: 0.9
  add search_businesses_path, changefreq: "daily",  priority: 0.8
  add for_estate_clearance_businesses_path, changefreq: "weekly", priority: 0.8
  add for_resellers_businesses_path,        changefreq: "weekly", priority: 0.8

  # 業者詳細ページ（公開中の業者のみ）
  Business.where(active: true, approval_status: :approved).find_each do |biz|
    add business_path(biz),
        lastmod:     biz.updated_at,
        changefreq:  "weekly",
        priority:    0.7
  end

  # 業者登録
  add select_type_businesses_path, changefreq: "monthly", priority: 0.6
  add new_business_path,           changefreq: "monthly", priority: 0.5

  # ユーザー登録・ログイン
  add new_user_registration_path, changefreq: "monthly", priority: 0.6
  add new_user_session_path,      changefreq: "monthly", priority: 0.5

  # ゲスト査定
  add new_guest_assessment_path,  changefreq: "weekly",  priority: 0.7
end
