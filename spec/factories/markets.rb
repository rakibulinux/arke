# frozen_string_literal: true

FactoryBot.define do
  factory :market do
    association :exchange, strategy: :create
    trait :btcusd do
      name { "BTCUSD" }
      base { "BTC" }
      quote { "USD" }
      base_precision { Faker::Number.between(from: 1, to: 8) }
      quote_precision { Faker::Number.between(from: 1, to: 2) }
      state { "enabled" }
    end

    trait :ethusd do
      name { "ETHUSD" }
      base { "ETH" }
      quote { "USD" }
      base_precision { Faker::Number.between(from: 1, to: 5) }
      quote_precision { Faker::Number.between(from: 1, to: 2) }
      state { "enabled" }
    end
  end
end
