FactoryBot.define do
  factory :journey_configuration, class: "journeys/configuration" do
    current_academic_year { AcademicYear.current }

    trait :student_loans do
      routing_name { Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME }
    end

    trait :additional_payments do
      routing_name { Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME }
    end

    trait :targeted_retention_incentive_payments do
      routing_name { Journeys::TargetedRetentionIncentivePayments::ROUTING_NAME }
    end

    trait :get_a_teacher_relocation_payment do
      routing_name { Journeys::GetATeacherRelocationPayment::ROUTING_NAME }
    end

    trait :international_relocation_payments do
      routing_name { Journeys::GetATeacherRelocationPayment::ROUTING_NAME }
    end

    trait :early_career_payments do
      additional_payments
    end

    trait :targeted_retention_incentive_payments do
      additional_payments
    end

    trait :further_education_payments do
      routing_name { Journeys::FurtherEducationPayments::ROUTING_NAME }
    end

    trait :further_education_payments_provider do
      routing_name { Journeys::FurtherEducationPayments::Provider::ROUTING_NAME }
    end

    trait :early_years_payment_provider_start do
      routing_name { Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME }
    end

    trait :early_years_payment_provider_authenticated do
      routing_name { Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME }
    end

    trait :early_years_payment_practitioner do
      routing_name { Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME }
    end

    trait :early_years_payments do
      routing_name { Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME }
    end

    trait :closed do
      open_for_submissions { false }
    end
  end
end
