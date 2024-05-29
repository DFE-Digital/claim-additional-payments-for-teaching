FactoryBot.define do
  factory :additional_payments_answers, class: "Journeys::AdditionalPaymentsForTeaching::SessionAnswers" do
    trait :with_personal_details do
      first_name { "Jo" }
      surname { "Bloggs" }
      date_of_birth { 20.years.ago.to_date }
      national_insurance_number { generate(:national_insurance_number) }
    end

    trait :with_details_from_dfe_identity do
      with_personal_details
      teacher_reference_number { generate(:teacher_reference_number) }
    end

    trait :with_email_details do
      email_address { generate(:email_address) }
      email_verified { true }
    end
  end
end
