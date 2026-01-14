FactoryBot.define do
  factory :generation do
    user
    source_text { Faker::Lorem.paragraph_by_chars(number: 1000) }
  end
end
