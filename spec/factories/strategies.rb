FactoryBot.define do
  factory :strategy do
    user { create(:user) }
    source { create(:account) }
    target { create(:account) }
    source_market { create(:market, :btcusd) }
    target_market { create(:market, :ethusd) }
    name { Faker::Alphanumeric.alpha(7) }
    driver { %w(copy microtrades).sample }
    interval { Faker::Number.number(1) }
    params { JSON.dump({}) }
    state { 'active' }
  end
end
