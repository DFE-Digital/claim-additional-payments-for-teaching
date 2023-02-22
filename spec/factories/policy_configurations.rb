FactoryBot.define do
  factory :policy_configuration do
    current_academic_year { AcademicYear.current }

    trait :student_loans do
      policy_types { [StudentLoans] }
    end

    trait :maths_and_physics do
      policy_types { [MathsAndPhysics] }
      current_academic_year { AcademicYear.new("2020/2021") } # Maths and Physics policy was discontinued after 2021
    end

    trait :additional_payments do
      policy_types { [EarlyCareerPayments, LevellingUpPremiumPayments] }
    end

    trait :early_career_payments do
      additional_payments
    end

    trait :levelling_up_premium_payments do
      additional_payments
    end

    trait :simple_policy_payments do
      policy_types { [SimplePolicyPayments] }
    end

    trait :closed do
      open_for_submissions { false }
    end
  end
end
