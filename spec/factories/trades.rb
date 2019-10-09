FactoryBot.define do
  factory :trade do
    account { create(:account) }
    market { create(:market, :btcusd) }
    tid { Faker::Alphanumeric.alpha(7) }
    side { Faker::Number.number(digits: 1) }
    price { Faker::Number.decimal(l_digits: 2) }
    amount { Faker::Number.decimal(l_digits: 2) }
    fee { Faker::Number.decimal(l_digits: 2) }
  end
end
