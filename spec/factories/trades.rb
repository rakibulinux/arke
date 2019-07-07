FactoryBot.define do
  factory :trade do
    credential { nil }
    market { nil }
    tid { "MyString" }
    side { 1 }
    price { "9.99" }
    amount { "9.99" }
    fee { "9.99" }
  end
end
