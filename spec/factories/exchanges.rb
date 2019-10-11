FactoryBot.define do
  factory :exchange do
    name { Exchange::EXCHANGE_NAMES.sample }
    url { Faker::Internet.url }
    rest { Faker::Internet.url }
    ws { %w[ws://binance.com ws://1lol.com].sample }
    rate { Faker::Number.decimal(2) }
  end
end
