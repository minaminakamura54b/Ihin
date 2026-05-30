puts "シードデータを作成中..."

# ============================================================
# 開発環境用（テストデータ）
# ============================================================
if Rails.env.development?

  # 開発用パスワード（複雑性要件: 英字+数字+記号）
  DEV_PASSWORD = "Minami@1"

  # 管理者（確認済みとして作成→ログイン可能）
  admin = User.new(
    email: "admin@ihin-app.jp",
    name: "管理者",
    password: DEV_PASSWORD,
    role: :admin
  )
  admin.skip_confirmation!
  admin.save!
  puts "管理者: #{admin.email}"

  # 遺族ユーザー（after_createでTodoItemが自動作成される・確認済み）
  family = User.new(
    email: "tanaka@example.com",
    name: "田中 花子",
    password: DEV_PASSWORD,
    role: :family
  )
  family.skip_confirmation!
  family.save!
  puts "遺族ユーザー: #{family.email}"

  # ─── 業者1: 遺品整理（東京・神奈川）───
  biz1_user = User.new(
    email: "business@example.com",
    name: "山田 太郎",
    password: DEV_PASSWORD,
    role: :business
  )
  biz1_user.skip_confirmation!
  biz1_user.save!
  biz1_user.business.update!(
    name:                "東京遺品整理センター",
    category:            :estate_clearance,
    area:                "東京都・神奈川県対応",
    service_prefectures: %w[東京都 神奈川県],
    description:         "20年の実績を持つ遺品整理の専門業者です。遺族の気持ちに寄り添い、丁寧な作業を心がけています。生前整理のご相談も承ります。",
    phone:               "03-1234-5678",
    website:             "https://example.com/business",
    plan:                :standard,
    active:              true,
    approval_status:     :approved
  )
  puts "業者1: #{biz1_user.email}"

  # ─── 業者2: 買取（全国対応）───
  biz2_user = User.new(
    email: "buyback@example.com",
    name: "鈴木 次郎",
    password: DEV_PASSWORD,
    role: :business
  )
  biz2_user.skip_confirmation!
  biz2_user.save!
  biz2_user.business.update!(
    name:                "全国買取りハウス",
    category:            :buyback,
    area:                "全国対応",
    service_prefectures: Business::VALID_PREFECTURES,
    description:         "骨董品・貴金属・ブランド品・家電など幅広く高価買取します。出張査定無料。遺品整理時の一括買取も対応。",
    phone:               "0120-000-001",
    plan:                :basic,
    active:              true,
    approval_status:     :approved
  )
  puts "業者2: #{biz2_user.email}"

  # ─── 業者3: 不動産（大阪・京都・兵庫）───
  biz3_user = User.new(
    email: "realestate@example.com",
    name: "佐藤 三郎",
    password: DEV_PASSWORD,
    role: :business
  )
  biz3_user.skip_confirmation!
  biz3_user.save!
  biz3_user.business.update!(
    name:                "関西不動産サポート",
    category:            :real_estate,
    area:                "大阪府・京都府・兵庫県",
    service_prefectures: %w[大阪府 京都府 兵庫県],
    description:         "相続不動産・空き家の売却・活用をトータルサポートします。初回相談無料。",
    phone:               "06-1234-5678",
    plan:                :free,
    active:              true,
    approval_status:     :approved
  )
  puts "業者3: #{biz3_user.email}"

  puts "業者合計: #{Business.count}件"

  # テスト用問い合わせ（業者1宛）
  biz = biz1_user.business

  # 1件目: 田中さんから（メール）
  Inquiry.create!(
    user: family, business: biz,
    contact_type: :email, contact_info: "tanaka@example.com",
    message: "父が先月亡くなりました。一人暮らしの1LDKの部屋の遺品整理をお願いしたいのですが、費用の目安を教えていただけますか？",
    status: :pending
  )

  # 2件目: 別ユーザーから（電話）
  family2 = User.new(
    email: "yamamoto@example.com",
    name: "山本 次郎",
    password: DEV_PASSWORD,
    role: :family
  )
  family2.skip_confirmation!
  family2.save!
  Inquiry.create!(
    user: family2, business: biz,
    contact_type: :phone, contact_info: "090-0000-0002",
    message: "母の遺品整理をお願いしたいです。2LDKのマンションです。",
    status: :contacted
  )

  # テスト用遺品
  Item.create!(user: family, name: "祖父の腕時計", memo: "金無垢のロレックス。祖父が大切にしていた形見です。")
  Item.create!(user: family, name: "着物セット",   memo: "祖母が嫁入り道具として持参したもの。状態は良好です。")
  Item.create!(user: family, name: "ブランドバッグ", memo: "ルイヴィトンのモノグラム。使用感あり。")

  puts "遺品: #{Item.count}件作成"
  puts "問い合わせ: #{Inquiry.count}件作成"
  puts "やることリスト: #{TodoItem.count}件作成"
  puts ""
  puts "シードデータの作成が完了しました！"
  puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  puts "ログイン情報（パスワードはすべて: #{DEV_PASSWORD}）"
  puts "  管理者: admin@ihin-app.jp"
  puts "  遺族:   tanaka@example.com"
  puts "  業者1（遺品整理）: business@example.com"
  puts "  業者2（買取）:     buyback@example.com"
  puts "  業者3（不動産）:   realestate@example.com"
  puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

end

# ============================================================
# 本番環境用（管理者のみ・環境変数から読む）
# ============================================================
if Rails.env.production?

  unless ENV["ADMIN_EMAIL"] && ENV["ADMIN_PASSWORD"]
    puts "エラー: ADMIN_EMAIL と ADMIN_PASSWORD を環境変数に設定してください"
    exit 1
  end

  admin = User.find_or_initialize_by(email: ENV["ADMIN_EMAIL"])
  if admin.new_record?
    admin.assign_attributes(
      name:     ENV.fetch("ADMIN_NAME", "管理者"),
      password: ENV["ADMIN_PASSWORD"],
      role:     :admin
    )
    admin.save!
    puts "管理者を作成しました: #{admin.email}"
  else
    puts "管理者はすでに存在します: #{admin.email}（スキップ）"
  end

end
