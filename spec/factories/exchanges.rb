FactoryBot.define do
  factory :exchange do
    name { Exchange::EXCHANGE_NAMES.sample }
    url { Faker::Internet.url }
    rest { Faker::Internet.url }
    ws { Faker::Internet.url }
    rate { Faker::Number.decimal(l_digits: 2) }
  end
end
