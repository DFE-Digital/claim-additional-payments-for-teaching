FactoryBot.define do
  factory :early_years_payment_practitioner_answers, class: "Journeys::EarlyYearsPayment::Practitioner::SessionAnswers" do
    trait :eligible do
      academic_year { AcademicYear.current }
      email_address { "practitioner@example.com" }
      email_verified { true }
      first_name { "John" }
      surname { "Doe" }
      provide_mobile_number { false }
      national_insurance_number { generate(:national_insurance_number) }
      date_of_birth { 20.years.ago.to_date }
      banking_name { "John Doe" }
      bank_sort_code { rand(100000..999999) }
      bank_account_number { rand(10000000..99999999) }
      practitioner_claim_started_at { 30.minutes.ago }
    end

    trait :submittable do
      eligible
    end
  end
end
