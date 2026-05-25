FactoryBot.define do
  factory :memory do
    association :user
    sequence(:comment) { |n| "思い出のエピソード#{n}" }

    trait :with_item do
      association :item
    end
  end
end
