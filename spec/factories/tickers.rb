FactoryBot.define do
  factory :ticker do
    market { create(:market, :btcusd) }
    mid {  Faker::Number.decimal(2) }
    bid {  Faker::Number.decimal(2) }
    ask {  Faker::Number.decimal(2) }
    last {  Faker::Number.decimal(2) }
    low {  Faker::Number.decimal(2) }
    high {  Faker::Number.decimal(2) }
    volume {  Faker::Number.decimal(2) }
  end
end
