FactoryBot.define do
  factory :balance do
    account { create(:account) }
    currency { %w(eth usd btc).sample }
    amount { Faker::Number.decimal(l_digits: 2) }
    available { Faker::Number.decimal(l_digits: 2) }
    locked { Faker::Number.decimal(l_digits: 2) }
  end
end
