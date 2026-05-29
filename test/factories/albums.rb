FactoryBot.define do
  factory :album do
    association :user
    sequence(:title) { |n| "テストアルバム#{n}" }
    description { "アルバムの説明" }
    shared { false }
  end
end
