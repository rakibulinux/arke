FactoryBot.define do
  factory :ticker do
    market { create(:market, :btcusd) }
    mid {  Faker::Number.decimal(l_digits: 2) }
    bid {  Faker::Number.decimal(l_digits: 2) }
    ask {  Faker::Number.decimal(l_digits: 2) }
    last {  Faker::Number.decimal(l_digits: 2) }
    low {  Faker::Number.decimal(l_digits: 2) }
    high {  Faker::Number.decimal(l_digits: 2) }
    volume {  Faker::Number.decimal(l_digits: 2) }
  end
end
