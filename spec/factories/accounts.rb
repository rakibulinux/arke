FactoryBot.define do
  factory :account do
    user { create(:user) }
    exchange { create(:exchange) }
    name { Faker::Dessert.variety }
  end
end
