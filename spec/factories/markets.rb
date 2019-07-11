FactoryBot.define do
  factory :market do
    trait :btcusd do
      name { 'BTCUSD' }
      base { 'BTC' }
      quote { 'USD' }
      exchange { create(:exchange) }
      base_precision { 8 }
      quote_precision { 2 }
      state { 'active' }
    end

    trait :ethusd do
      name { 'ETHUSD' }
      base { 'ETH' }
      quote { 'USD' }
      exchange { create(:exchange) }
      base_precision { 8 }
      quote_precision { 2 }
      state { 'active' }
    end
  end
end
