FactoryBot.define do
  factory :flashcard do
    user
    front { Faker::Lorem.paragraph }
    back { Faker::Lorem.paragraph }
    source { :manual }

    trait :manual do
      source { :manual }
    end

    trait :ai_full do
      source { :ai_full }
      generation
    end

    trait :ai_edited do
      source { :ai_edited }
      generation
    end
  end
end
