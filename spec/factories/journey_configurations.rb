FactoryBot.define do
  factory :journey_configuration, class: "journeys/configuration" do
    current_academic_year { AcademicYear.current }

    trait :student_loans do
      routing_name { Journeys::TeacherStudentLoanReimbursement.routing_name }
    end

    trait :get_a_teacher_relocation_payment do
      routing_name { Journeys::GetATeacherRelocationPayment.routing_name }
    end

    trait :international_relocation_payments do
      routing_name { Journeys::GetATeacherRelocationPayment.routing_name }
    end

    trait :targeted_retention_incentive_payments do
      routing_name { Journeys::TargetedRetentionIncentivePayments.routing_name }
    end

    trait :further_education_payments do
      routing_name { Journeys::FurtherEducationPayments.routing_name }
    end

    trait :further_education_payments_provider do
      routing_name { Journeys::FurtherEducationPayments::Provider.routing_name }
    end

    trait :early_years_payment_provider_start do
      routing_name { Journeys::EarlyYearsPayment::Provider::Start.routing_name }
    end

    trait :early_years_payment_provider_authenticated do
      routing_name { Journeys::EarlyYearsPayment::Provider::Authenticated.routing_name }
    end

    trait :early_years_payment_practitioner do
      routing_name { Journeys::EarlyYearsPayment::Practitioner.routing_name }
    end

    trait :early_years_payment_provider_alternative_idv do
      routing_name { Journeys::EarlyYearsPayment::Provider::AlternativeIdv.routing_name }
    end

    trait :early_years_payments do
      routing_name { Journeys::EarlyYearsPayment::Practitioner.routing_name }
    end

    trait :closed do
      open_for_submissions { false }
    end
  end
end
