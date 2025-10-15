FactoryBot.define do
  factory :further_education_payments_answers, class: "Journeys::FurtherEducationPayments::SessionAnswers" do
    trait :with_name do
      first_name { "Jo" }
      surname { "Bloggs" }
    end

    trait :with_details_from_onelogin do
      with_name
      onelogin_user_info { {"email" => "jo.bloggs@example.com"} }
    end

    trait :with_onelogin_credentials do
      onelogin_credentials { {"id_token" => "some_token"} }
    end

    trait :with_dob do
      date_of_birth { 20.years.ago.to_date }
    end

    trait :with_nino do
      national_insurance_number { generate(:national_insurance_number) }
    end

    trait :with_personal_details do
      with_details_from_onelogin
      with_dob
      with_nino
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

    trait :with_bank_details_validated do
      hmrc_bank_validation_succeeded { true }
      hmrc_bank_validation_responses do
        [
          {code: 200, body: "Test response"}
        ]
      end
    end

    trait :with_payroll_gender do
      payroll_gender { "female" }
    end

    trait :with_teacher_reference_number do
      teacher_reference_number { generate(:teacher_reference_number) }
    end

    trait :permanent do
      contract_type { "permanent" }
      teaching_hours_per_week { "more_than_12" }
    end

    trait :with_academic_year do
      academic_year { AcademicYear.current }
    end

    trait :eligible do
      teaching_responsibilities { true }
      school_id { create(:school, :further_education, :fe_eligible).id }
      permanent
      further_education_teaching_start_year { "2019" }
      subjects_taught { ["maths", "physics"] }
      maths_courses { ["approved_level_321_maths", "gcse_maths"] }
      physics_courses { ["gcse_physics"] }
      hours_teaching_eligible_subjects { true }
      half_teaching_hours { true }
      teaching_qualification { "yes" }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
    end

    trait :with_award_amount do
      award_amount { 4_000.0 }
    end

    trait :with_address do
      address_line_1 { "1 Test Road" }
      address_line_2 { "Some Second Line" }
      address_line_3 { "Some Town" }
      address_line_4 { "Some County" }
      postcode { "WIA OAA" }
    end

    trait :checked_answers_part_one do
      check_your_answers_part_one_completed { true }
    end

    trait :information_provided_completed do
      information_provided_completed { true }
    end

    trait :submittable do
      previously_claimed { false }
      have_one_login_account { "no" }

      with_academic_year
      eligible
      checked_answers_part_one
      information_provided_completed
      with_award_amount
      with_personal_details
      with_address
      with_email_details
      with_mobile_details
      with_bank_details
      with_bank_details_validated
      with_payroll_gender
    end
  end
end
