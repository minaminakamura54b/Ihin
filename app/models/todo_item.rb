class TodoItem < ApplicationRecord
  belongs_to :user

  enum :category, { urgent: 0, normal: 1, digital: 2 }

  validates :title, presence: true
  validates :user, presence: true

  scope :incomplete, -> { where(completed: false) }
  scope :complete, -> { where(completed: true) }
  scope :by_priority, -> { order(priority: :asc) }

  TEMPLATES = [
    # 急ぎ（数日以内）
    { title: "死亡診断書を受け取り、コピーを10枚以上取る",          category: :urgent, priority: 1 },
    { title: "役所に死亡届を提出する（7日以内）",                   category: :urgent, priority: 1 },
    { title: "火葬許可証を取得する",                               category: :urgent, priority: 1 },
    { title: "葬儀会社への連絡・手配",                             category: :urgent, priority: 1 },
    { title: "近親者・親族への連絡",                               category: :urgent, priority: 1 },
    { title: "故人の勤務先・学校への連絡",                          category: :urgent, priority: 1 },
    { title: "遺言書の有無を確認する",                             category: :urgent, priority: 2 },
    { title: "銀行口座の凍結前に当面の生活費を引き出す",             category: :urgent, priority: 1 },
    { title: "世帯主変更届を役所に提出する",                        category: :urgent, priority: 2 },
    { title: "健康保険証を返却する（14日以内）",                    category: :urgent, priority: 1 },
    # 通常（数週間〜数ヶ月以内）
    { title: "年金受給停止の手続き（年金事務所、14日以内）",          category: :normal, priority: 1 },
    { title: "国民健康保険の資格喪失届を提出する",                   category: :normal, priority: 1 },
    { title: "銀行・郵便局の口座相続手続き",                        category: :normal, priority: 1 },
    { title: "生命保険・死亡保険金の請求",                          category: :normal, priority: 1 },
    { title: "相続放棄が必要か検討する（3ヶ月以内に判断）",           category: :normal, priority: 1 },
    { title: "相続税の申告が必要か確認する（10ヶ月以内）",            category: :normal, priority: 2 },
    { title: "不動産の名義変更（相続登記）",                        category: :normal, priority: 2 },
    { title: "自動車の名義変更または廃車手続き",                     category: :normal, priority: 2 },
    { title: "携帯電話の解約または名義変更",                        category: :normal, priority: 2 },
    { title: "固定電話の解約または名義変更",                        category: :normal, priority: 3 },
    { title: "電気・ガス・水道の名義変更または解約",                  category: :normal, priority: 2 },
    { title: "NHKの解約または名義変更",                            category: :normal, priority: 3 },
    { title: "クレジットカードの解約",                              category: :normal, priority: 2 },
    { title: "運転免許証の返納手続き",                             category: :normal, priority: 3 },
    { title: "パスポートの失効手続き（市区町村役所）",               category: :normal, priority: 3 },
    { title: "マイナンバーカードの返却（役所）",                     category: :normal, priority: 3 },
    { title: "各種会員証・ポイントカードの解約",                     category: :normal, priority: 3 },
    { title: "賃貸契約の解約または名義変更",                        category: :normal, priority: 2 },
    { title: "遺品の整理・仕分け（売る／残す／処分）",               category: :normal, priority: 2 },
    { title: "お墓・納骨の手配",                                   category: :normal, priority: 2 },
    { title: "四十九日法要の準備",                                 category: :normal, priority: 2 },
    { title: "お世話になった方々へのお礼状・香典返し",               category: :normal, priority: 3 },
    # デジタル遺品
    { title: "スマートフォンのパスワード・PINを確認する",            category: :digital, priority: 1 },
    { title: "オンラインバンキングのアカウントを停止する",            category: :digital, priority: 1 },
    { title: "LINE・FacebookなどSNSアカウントを削除する",           category: :digital, priority: 2 },
    { title: "Twitter（X）・Instagramのアカウントを削除する",       category: :digital, priority: 2 },
    { title: "メールアカウントを整理・削除する",                    category: :digital, priority: 2 },
    { title: "NetflixやAmazon Primeなどの動画サービスを解約する",   category: :digital, priority: 2 },
    { title: "SpotifyなどMusicサービスを解約する",                 category: :digital, priority: 3 },
    { title: "Amazon・楽天などのネット通販アカウントを解約する",      category: :digital, priority: 2 },
    { title: "iCloud・Google Driveのデータを整理する",             category: :digital, priority: 2 },
    { title: "パソコンのデータをバックアップする",                   category: :digital, priority: 2 },
    { title: "ゲームアカウント・課金情報を整理する",                 category: :digital, priority: 3 },
    { title: "暗号資産（仮想通貨）の有無を確認する",                 category: :digital, priority: 1 },
    { title: "有料アプリ・サブスクの自動更新を停止する",             category: :digital, priority: 2 },
    { title: "ブログ・ウェブサイトの運営を停止・削除する",            category: :digital, priority: 3 }
  ].freeze

  def category_label
    case category
    when "urgent"  then "急ぎ"
    when "normal"  then "通常"
    when "digital" then "デジタル遺品"
    else category
    end
  end
end
