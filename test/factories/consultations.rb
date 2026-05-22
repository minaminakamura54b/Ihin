FactoryBot.define do
  factory :consultation do
    association :user
    message  { "相談メッセージ" }
    response { "AI回答テキスト" }
  end
end
