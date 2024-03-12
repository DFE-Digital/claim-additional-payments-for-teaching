FactoryBot.define do
  factory :journey_configuration do
    current_academic_year { AcademicYear.current }

    trait :student_loans do
      policy_types { [Policies::StudentLoans] }
    end

    trait :additional_payments do
      policy_types { [Policies::EarlyCareerPayments, LevellingUpPremiumPayments] }
    end

    trait :early_career_payments do
      additional_payments
    end

    trait :levelling_up_premium_payments do
      additional_payments
    end

    trait :closed do
      open_for_submissions { false }
    end
  end
end
