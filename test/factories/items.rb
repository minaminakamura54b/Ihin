FactoryBot.define do
  factory :item do
    association :user
    sequence(:name) { |n| "遺品#{n}" }
    action { :undecided }

    trait :assessed do
      ai_result { "査定済みの結果テキスト" }
      estimated_price { 50_000 }
      action { :sell }
    end

    trait :pending_assessment do
      ai_result { nil }
    end
  end
end
