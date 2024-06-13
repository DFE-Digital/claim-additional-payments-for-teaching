FactoryBot.define do
  factory :student_loans_answers, class: "Journeys::TeacherStudentLoanReimbursement::SessionAnswers" do
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

    trait :with_claim_school do
      claim_school_id { create(:school, :student_loans_eligible).id }
    end

    trait :with_current_school do
      current_school_id { create(:school, :student_loans_eligible).id }
    end

    trait :with_subjects_taught do
      physics_taught { true }
      taught_eligible_subjects { true }
    end

    trait :with_employment_status do
      employment_status { :claim_school }
    end

    trait :with_leadership_position do
      had_leadership_position { true }
      mostly_performed_leadership_duties { false }
    end

    trait :with_qts_award_year do
      qts_award_year { "on_or_after_cut_off_date" }
    end

    trait :with_qualification_details_check do
      qualifications_details_check { true }
    end

    trait :submittable do
      with_personal_details
      with_email_details
      with_mobile_details
      with_bank_details
      with_payroll_gender
      with_teacher_reference_number
      with_claim_school
      with_current_school
      with_subjects_taught
      with_employment_status
      with_leadership_position
      with_qts_award_year
      with_qualification_details_check
    end
  end
end
