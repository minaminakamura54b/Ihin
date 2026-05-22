FactoryBot.define do
  factory :todo_item do
    association :user
    sequence(:title) { |n| "タスク#{n}" }
    category { :normal }
    priority { 1 }
    completed { false }

    trait :urgent  do; category { :urgent };  end
    trait :digital do; category { :digital }; end

    trait :completed do
      completed { true }
    end
  end
end
