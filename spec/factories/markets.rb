FactoryBot.define do
  factory :market do
    exchange { nil }
    quote { "USD" }
    base_precision { 8 }
    quote_precision { 2 }
    state { "active" }

    trait :btcusd do
      name { "BTCUSD" }
      base { "BTC" }
    end

    trait :ethusd do
      name { "ETHUSD" }
      base { "ETH" }
      base_precision { 5 }
    end
  end
end
