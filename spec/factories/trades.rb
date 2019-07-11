FactoryBot.define do
  factory :trade do
    account { create(:account) }
    market { create(:market, :btcusd) }
    tid { Faker::Alphanumeric.alpha(7) }
    side { Faker::Number.number(1) }
    price { Faker::Number.decimal(2) }
    amount { Faker::Number.decimal(2) }
    fee { Faker::Number.decimal(2) }
  end
end
