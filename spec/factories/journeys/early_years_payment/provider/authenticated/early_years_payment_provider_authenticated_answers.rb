FactoryBot.define do
  factory :early_years_payment_provider_authenticated_answers, class: "Journeys::EarlyYearsPayment::Provider::Authenticated::SessionAnswers" do
    trait :eligible do
      academic_year { AcademicYear.current }
      email_address { nil }
      email_verified { nil }
      consent_given { true }
      nursery_urn { create(:eligible_ey_provider).urn }
      paye_reference { "123/A" }
      first_name { "John" }
      surname { "Doe" }
      practitioner_first_name { "John" }
      practitioner_surname { "Doe" }
      start_date { Policies::EarlyYearsPayments::ELIGIBLE_START_DATE + 1.day }
      child_facing_confirmation_given { true }
      returning_within_6_months { true }
      practitioner_email_address { "johndoe@example.com" }
      provide_mobile_number { false }
      provider_email_address { "provider@example.com" }
    end

    trait :submittable do
      eligible
      provider_contact_name { "John Doe" }
    end
  end
end
