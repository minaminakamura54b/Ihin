class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { family: 0, business: 1, admin: 2 }

  has_many :items, dependent: :destroy
  has_many :todo_items, dependent: :destroy
  has_many :memories, dependent: :destroy
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
    create_business!(
      name: "#{name}の会社",
      plan: :free,
      active: true
    )
  end
end
