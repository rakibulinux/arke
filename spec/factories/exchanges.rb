FactoryBot.define do
  factory :exchange do

    name { %w(binance bitfaker bitfinex hitbtc huobi kraken luno okex rubykube).sample }
    url { Faker::Internet.url }
    rest { Faker::Internet.url }
    ws { Faker::Internet.url }
    rate { Faker::Number.decimal(2) }
  end
end
