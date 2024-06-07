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

    trait :with_payroll_gender do
      payroll_gender { "female" }
    end

    trait :with_teacher_reference_number do
      teacher_reference_number { generate(:teacher_reference_number) }
    end

    trait :with_qualification_details_check do
      qualifications_details_check { true }
    end

    trait :with_qualification do
      qualification { "postgraduate_itt" }
    end

    trait :submittable do
      with_personal_details
      with_email_details
      with_mobile_details
      with_bank_details
      with_payroll_gender
      with_teacher_reference_number
      with_qualification_details_check
      with_qualification
    end
  end
end
