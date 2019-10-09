FactoryBot.define do
  factory :user do
    uid { Faker::Alphanumeric.alphanumeric(number: 10) }
    email { Faker::Internet.email }
    level { rand(1..4) }
    role { %w(admin trader broker).sample }
    state { %w(active disabled).sample }
    created_at { Faker::Date.backward(days: 90) }
    updated_at { Faker::Date.backward(days: 90) }
  end
end
