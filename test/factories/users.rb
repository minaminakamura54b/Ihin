FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name)  { |n| "テストユーザー#{n}" }
    password { "Password1" }
    password_confirmation { "Password1" }
    role { :family }
    # テストではメール確認なしで即サインインできるよう確認済みにする
    confirmed_at { Time.current }
    confirmation_sent_at { Time.current }

    trait :business_role do
      role { :business }
      # after_create で create_free_business が走り Business が自動生成される
    end

    trait :admin do
      role { :admin }
    end
  end
end
