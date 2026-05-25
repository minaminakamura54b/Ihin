puts "シードデータを作成中..."

# ============================================================
# 開発環境用（テストデータ）
# ============================================================
if Rails.env.development?

  # 管理者
  admin = User.create!(
    email: "admin@ihin-app.jp",
    name: "管理者",
    password: "minami",
    role: :admin
  )
  puts "管理者: #{admin.email}"

  # 遺族ユーザー（after_createでTodoItemが自動作成される）
  family = User.create!(
    email: "tanaka@example.com",
    name: "田中 花子",
    password: "minami",
    role: :family
  )
  puts "遺族ユーザー: #{family.email}"

  # 業者ユーザー（after_createで無料プランのBusinessが自動作成される）
  business_user = User.create!(
    email: "business@example.com",
    name: "山田 太郎",
    password: "minami",
    role: :business
  )
  business_user.business.update!(
    name: "東京遺品整理センター",
    category: :estate_clearance,
    area: "東京都・神奈川県",
    description: "20年の実績を持つ遺品整理の専門業者です。遺族の気持ちに寄り添い、丁寧な作業を心がけています。生前整理のご相談も承ります。",
    phone: "03-1234-5678",
    website: "https://example.com/business",
    plan: :standard,
    active: true
  )
  puts "業者: #{business_user.email}"

  # 追加の業者（一覧ページ用）
  biz2_user = User.create!(
    email: "buyback@example.com",
    name: "鈴木 次郎",
    password: "minami",
    role: :business
  )
  biz2_user.business.update!(
    name: "全国買取りハウス",
    category: :buyback,
    area: "全国対応",
    description: "骨董品・貴金属・ブランド品・家電など幅広く高価買取します。出張査定無料。遺品整理時の一括買取も対応。",
    phone: "0120-000-001",
    plan: :basic,
    active: true
  )

  biz3_user = User.create!(
    email: "lawyer@example.com",
    name: "佐藤 三郎",
    password: "minami",
    role: :business
  )
  biz3_user.business.update!(
    name: "佐藤法律事務所",
    category: :judicial_scrivener,
    area: "東京都",
    description: "相続・遺言・不動産登記を専門とする司法書士事務所。初回相談無料。",
    phone: "03-9876-5432",
    plan: :free,
    active: true
  )

  puts "業者合計: #{Business.count}件"

  # テスト用問い合わせ
  biz = business_user.business
  Inquiry.create!(user: family, business: biz, message: "父が先月亡くなりました。一人暮らしの1LDKの部屋の遺品整理をお願いしたいのですが、費用の目安を教えていただけますか？", status: :pending)
  Inquiry.create!(user: family, business: biz, message: "先日ご連絡した田中です。見積もりをいただいた件について、もう少し詳しく聞かせてください。", status: :contacted)
  Inquiry.create!(user: family, business: biz, message: "先月対応していただきありがとうございました。おかげさまで無事に整理が終わりました。", status: :closed)

  # テスト用遺品
  Item.create!(user: family, name: "祖父の腕時計", memo: "金無垢のロレックス。祖父が大切にしていた形見です。")
  Item.create!(user: family, name: "着物セット", memo: "祖母が嫁入り道具として持参したもの。状態は良好です。")
  Item.create!(user: family, name: "ブランドバッグ", memo: "ルイヴィトンのモノグラム。使用感あり。")

  puts "遺品: #{Item.count}件作成"
  puts "問い合わせ: #{Inquiry.count}件作成"
  puts "やることリスト: #{TodoItem.count}件作成"
  puts ""
  puts "シードデータの作成が完了しました！"
  puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  puts "ログイン情報（パスワードはすべて: minami）"
  puts "  管理者: admin@ihin-app.jp"
  puts "  遺族:   tanaka@example.com"
  puts "  業者:   business@example.com"
  puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

end

# ============================================================
# 本番環境用（管理者のみ・環境変数から読む）
# ============================================================
if Rails.env.production?

  # 環境変数チェック
  unless ENV["ADMIN_EMAIL"] && ENV["ADMIN_PASSWORD"]
    puts "エラー: ADMIN_EMAIL と ADMIN_PASSWORD を環境変数に設定してください"
    exit 1
  end

  # すでに管理者がいれば作成をスキップ
  admin = User.find_or_initialize_by(email: ENV["ADMIN_EMAIL"])

  if admin.new_record?
    admin.assign_attributes(
      name: ENV.fetch("ADMIN_NAME", "管理者"),
      password: ENV["ADMIN_PASSWORD"],
      role: :admin
    )
    admin.save!
    puts "管理者を作成しました: #{admin.email}"
  else
    puts "管理者はすでに存在します: #{admin.email}（スキップ）"
  end

end
