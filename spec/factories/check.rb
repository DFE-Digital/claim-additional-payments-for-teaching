FactoryBot.define do
  factory :check do
    checked_by { "123" }

    trait :approved do
      result { :approved }
    end
  end
end
