FactoryBot.define do
  factory :inquiry do
    association :user
    association :business
    message { "お問い合わせメッセージです" }
    status { :pending }

    trait :with_item do
      association :item
    end

    trait :contacted do
      status { :contacted }
    end

    trait :closed do
      status { :closed }
    end
  end
end
