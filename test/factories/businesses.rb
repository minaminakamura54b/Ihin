FactoryBot.define do
  factory :business do
    # business roleのUser作成時に after_create で Business が自動生成されるため、
    # skip_create + initialize_with で既存レコードを取得・更新して返す
    skip_create

    association :user, factory: [:user, :business_role]
    name { "テスト遺品整理業者" }
    area { "神奈川県横浜市" }
    plan { :free }
    active { true }
    category { :estate_clearance }

    initialize_with do
      biz = user.business
      biz.update!(name: name, area: area, plan: plan, active: active, category: category)
      biz
    end

    trait :basic_plan    do; plan { :basic };    end
    trait :standard_plan do; plan { :standard }; end
    trait :premium_plan  do; plan { :premium };  end
    trait :inactive      do; active { false };   end
  end
end
