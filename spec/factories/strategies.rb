FactoryBot.define do
  factory :strategy do
    association :user, strategy: :create
    association :account, strategy: :create
    association :account, strategy: :create
    association :market, trait: :btcusd, strategy: :create
    name { Faker::Alphanumeric.alpha(7) }
    driver { %w(copy microtrades).sample }
    interval { Faker::Number.number(digits: 1) }
    params { JSON.dump({}) }
    state { 'active' }
  end
end
