FactoryBot.define do
  factory :strategy do
    user { nil }
    source { nil }
    target { nil }
    name { "MyString" }
    driver { "copy" }
    frequency { 1 }
    params { "" }
    state { "active" }
    debug { false }
  end
end
