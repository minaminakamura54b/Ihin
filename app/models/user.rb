class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  enum :role, { family: 0, business: 1, admin: 2 }, default: :family

  has_many :items, dependent: :destroy
  has_many :todo_items, dependent: :destroy
  has_many :memories, dependent: :destroy
  has_many :digital_items, dependent: :destroy
  has_many :bulk_assessments, dependent: :destroy
  has_one :business, dependent: :destroy
  has_many :inquiries, dependent: :destroy
  has_many :consultations, dependent: :destroy

  validates :name, presence: true

  after_create :create_default_todos, if: :family?
  after_create :create_free_business, if: :business?

  def business_user?
    business? && business.present? && business.active?
  end

  private

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
end
