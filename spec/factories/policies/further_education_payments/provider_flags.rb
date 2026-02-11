FactoryBot.define do
  factory :further_education_payments_provider_flag, class: "Policies::FurtherEducationPayments::ProviderFlag" do
    ukprn { 123456 }
    academic_year { AcademicYear.current }
    reason { "clawback" }
  end
end
