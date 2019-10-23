FactoryBot.define do
  factory :account do
    association :user, strategy: :create
    association :exchange, strategy: :create
    name { Faker::Internet.slug }
  end
end
