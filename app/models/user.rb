class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :timeoutable

  enum :role, { family: 0, business: 1, admin: 2 }, default: :family

  has_many :items, dependent: :destroy
  has_many :todo_items, dependent: :destroy
  has_many :memories, dependent: :destroy
  has_many :albums, dependent: :destroy
  has_many :digital_items, dependent: :destroy
  has_many :bulk_assessments, dependent: :destroy
  has_one :business, dependent: :destroy
  has_many :inquiries, dependent: :destroy
  has_many :consultations, dependent: :destroy
  has_many :password_histories, dependent: :destroy

  validates :name, presence: true

  # パスワード複雑性チェック（新規設定・変更時のみ実行）
  validate :validate_password_complexity, if: -> { password.present? }
  # 直近3回と同じパスワード禁止
  validate :validate_password_history, if: -> { password.present? && !new_record? }

  after_create :create_default_todos, if: :family?
  after_create :create_free_business, if: :business?
  before_create :generate_album_token
  before_create :generate_session_token

  # パスワード変更時：全デバイスのセッションを無効化するためトークンを更新
  after_update :rotate_session_token_and_save_history, if: :saved_change_to_encrypted_password?
  # ロール変更時：権限が変わったため全デバイスを強制ログアウト
  after_update :rotate_session_token_on_role_change, if: :saved_change_to_role?

  def business_user?
    business? && business.present? && business.active?
  end

  # familyユーザーはメール認証完了前にログイン不可（猶予期間なし）
  # business/adminはDeviseデフォルト（allow_unconfirmed_access_for = 3.days）に委譲
  def active_for_authentication?
    return super if business? || admin?
    confirmed?
  end

  def inactive_message
    return super if business? || admin?
    confirmed? ? super : :unconfirmed
  end

  private

  def validate_password_complexity
    return if password.blank?
    # 長さはDeviseのpassword_lengthで検証済みのため省略
    errors.add(:password, "には大文字（A-Z）を1文字以上含めてください") unless password.match?(/[A-Z]/)
    errors.add(:password, "には数字（0-9）を1文字以上含めてください") unless password.match?(/\d/)
  end

  def validate_password_history
    recent = password_histories.order(created_at: :desc).limit(3)
    if recent.any? { |ph| BCrypt::Password.new(ph.encrypted_password) == password }
      errors.add(:password, "は直近3回と同じパスワードは使用できません")
    end
  end

  def rotate_session_token_on_role_change
    # ロール変更（family→businessなど）で権限が変わるため全デバイスのセッションを無効化
    update_column(:session_token, SecureRandom.hex(32))
  end

  def rotate_session_token_and_save_history
    # パスワード履歴を保存（古いencrypted_passwordが保存済みなので現在値を使う）
    password_histories.create!(encrypted_password: encrypted_password)
    # 最新3件を超える古い履歴を削除
    old_ids = password_histories.order(created_at: :desc).offset(3).pluck(:id)
    password_histories.where(id: old_ids).delete_all
    # セッショントークンを更新してすべてのデバイスを強制ログアウト
    update_column(:session_token, SecureRandom.hex(32))
    update_column(:password_changed_at, Time.current)
  end

  def create_default_todos
    TodoItem::TEMPLATES.each do |t|
      todo_items.create!(title: t[:title], category: t[:category], priority: t[:priority])
    end
  end

  def create_free_business
    # 新規業者登録時は審査待ち・非公開状態で作成する
    create_business!(
      name: "#{name}の会社",
      plan: :free,
      active: false,
      approval_status: :pending
    )
  end

  def generate_album_token
    self.album_token = SecureRandom.urlsafe_base64(16)
  end

  def generate_session_token
    self.session_token = SecureRandom.hex(32)
  end
end
