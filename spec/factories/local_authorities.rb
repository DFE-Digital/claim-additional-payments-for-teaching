FactoryBot.define do
  factory :local_authority do
    sequence(:code) { |n| 1000 + n }
    name { Faker::Address.community }

    initialize_with { LocalAuthority.find_or_create_by(code: code) }

    trait :student_loans_eligible do
      code { StudentLoans::SchoolEligibility::ELIGIBLE_LOCAL_AUTHORITY_CODES.sample }
    end

    trait :student_loans_ineligible do
      code { ["202", "304"].sample }
    end
  end
end
