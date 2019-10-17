# frozen_string_literal: true

FactoryBot.define do
  factory :market do
    trait :btcusd do
      name { "BTCUSD" }
      base { "BTC" }
      quote { "USD" }
      exchange { create(:exchange) }
      base_precision { Faker::Number.between(from: 1, to: 5) }
      quote_precision { Faker::Number.between(from: 1, to: 5) }
      state { "active" }
    end

    trait :ethusd do
      name { "ETHUSD" }
      base { "ETH" }
      quote { "USD" }
      exchange { create(:exchange) }
      base_precision { Faker::Number.between(from: 1, to: 5) }
      quote_precision { Faker::Number.between(from: 1, to: 5) }
      state { "active" }
    end
  end
end
