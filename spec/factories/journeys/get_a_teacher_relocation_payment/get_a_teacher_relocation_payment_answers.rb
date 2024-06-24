FactoryBot.define do
  factory :get_a_teacher_relocation_payment_answers, class: "Journeys::GetATeacherRelocationPayment::SessionAnswers" do
    trait :with_personal_details do
      first_name { "Jo" }
      surname { "Bloggs" }
      date_of_birth { 20.years.ago.to_date }
      national_insurance_number { generate(:national_insurance_number) }
    end

    trait :with_teacher_application_route do
      application_route { "teacher" }
    end

    trait :with_trainee_application_route do
      application_route { "salaried_trainee" }
    end

    trait :with_state_funded_secondary_school do
      state_funded_secondary_school { true }
    end

    trait :with_one_year_contract do
      one_year { true }
    end

    trait :with_start_date do
      start_date { Date.tomorrow }
    end

    trait :with_email_details do
      email_address { generate(:email_address) }
      email_verified { true }
    end

    trait :with_mobile_details do
      mobile_number { "07474000123" }
      provide_mobile_number { true }
      mobile_verified { true }
    end

    trait :with_bank_details do
      bank_or_building_society { :personal_bank_account }
      banking_name { "Jo Bloggs" }
      bank_sort_code { rand(100000..999999) }
      bank_account_number { rand(10000000..99999999) }
    end

    trait :eligible_teacher do
      with_teacher_application_route
      with_state_funded_secondary_school
      with_one_year_contract
      with_start_date
    end
  end
end
