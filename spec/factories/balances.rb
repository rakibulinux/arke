FactoryBot.define do
  factory :balance do
    association :account, strategy: :create
    currency { Balance::CURRENCY_NAME.sample }
    amount { Faker::Number.decimal(l_digits: 2) }
    locked { Faker::Number.decimal(l_digits: 2) }
  end
end
