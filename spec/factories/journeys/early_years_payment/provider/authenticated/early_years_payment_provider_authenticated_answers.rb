FactoryBot.define do
  factory :early_years_payment_provider_authenticated_answers, class: "Journeys::EarlyYearsPayment::Provider::Authenticated::SessionAnswers" do
    trait :eligible do
      academic_year { AcademicYear.current }
      email_address { "provider@example.com" }
      email_verified { true }
      consent_given { true }
      nursery_urn { create(:eligible_ey_provider).urn }
      paye_reference { "123/A" }
      first_name { "John" }
      surname { "Doe" }
      start_date { Date.parse("1/1/2024") }
      child_facing_confirmation_given { true }
      first_job_within_6_months { true }
      practitioner_email_address { "johndoe@example.com" }
      provide_mobile_number { false }
    end

    trait :submittable do
      eligible
      provider_contact_name { "John Doe" }
    end
  end
end
