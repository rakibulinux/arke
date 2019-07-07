FactoryBot.define do
  factory :ticker do
    market { nil }
    mid { "9.99" }
    bid { "9.99" }
    ask { "9.99" }
    last { "9.99" }
    low { "9.99" }
    high { "9.99" }
    volume { "9.99" }
  end
end
