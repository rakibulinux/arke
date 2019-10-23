FactoryBot.define do
  factory :trade do
    association :account, strategy: :create
    association :market, :btcusd, strategy: :create
    tid { Faker::Alphanumeric.alpha(number: 7) }
    side { Faker::Number.number(digits: 1) }
    price { Faker::Number.decimal(l_digits: 2) }
    amount { Faker::Number.decimal(l_digits: 2) }
    fee { Faker::Number.decimal(l_digits: 2) }
  end
end
