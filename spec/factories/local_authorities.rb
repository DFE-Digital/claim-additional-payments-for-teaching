FactoryBot.define do
  factory :local_authority do
    sequence(:code)
    name { "York" }

    trait :eligible do
      code { 380 }
      name { "Bradford" }
    end

    trait :ineligible do
      code { 201 }
      name { "City of London" }
    end
  end
end
