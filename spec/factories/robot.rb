FactoryBot.define do
  factory :robot do
      association :user, strategy: :create
      strategy { Robot::STRATEGY_NAMES.sample }
      name { "robot" }
      state { Robot::STATES.sample }
  end
end
