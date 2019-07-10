FactoryBot.define do
  factory :account do
    user { create(:user) }
    exchange { create(:exchange) }
    name { Faker::Dessert.variety }
    api_key do
      {
        key: Faker::Number.hexadecimal(10),
        secret: Faker::Number.hexadecimal(20)
      }
    end
  end
end
