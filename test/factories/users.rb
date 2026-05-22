FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name)  { |n| "テストユーザー#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :family }

    trait :business_role do
      role { :business }
      # after_create で create_free_business が走り Business が自動生成される
    end

    trait :admin do
      role { :admin }
    end
  end
end
