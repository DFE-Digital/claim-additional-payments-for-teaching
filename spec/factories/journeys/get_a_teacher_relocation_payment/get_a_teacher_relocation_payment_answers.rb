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

    trait :with_current_school do
      current_school_id { create(:school).id }
    end

    trait :with_one_year_contract do
      one_year { true }
    end

    trait :with_start_date do
      start_date { Date.tomorrow }
    end

    trait :with_subject do
      subject { "physics" }
    end

    trait :with_changed_workplace_or_new_contract do
      changed_workplace_or_new_contract { false }
    end

    trait :with_breaks_in_employment do
      breaks_in_employment { true }
    end

    trait :with_visa do
      visa_type { "British National (Overseas) visa" }
    end

    trait :with_entry_date do
      with_start_date
      date_of_entry { start_date - 1.week }
    end

    trait :with_nationality do
      nationality { "Australian" }
    end

    trait :with_passport_number do
      passport_number { "1234567890123456789A" }
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

    trait :with_headteacher_details do
      school_headteacher_name { "Seymour Skinner" }
    end

    trait :eligible_teacher do
      with_teacher_application_route
      with_state_funded_secondary_school
      with_current_school
      with_headteacher_details
      with_one_year_contract
      with_subject
      with_changed_workplace_or_new_contract
      with_start_date
      with_visa
      with_entry_date
    end

    trait :submittable do
      eligible_teacher
      with_personal_details
      with_nationality
      with_passport_number
      with_email_details
      with_mobile_details
      with_bank_details
    end
  end
end
