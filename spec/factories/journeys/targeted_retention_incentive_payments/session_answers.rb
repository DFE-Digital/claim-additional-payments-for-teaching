FactoryBot.define do
  factory :targeted_retention_incentive_payments_answers, class: "Journeys::TargetedRetentionIncentivePayments::SessionAnswers" do
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

    trait :with_address_details do
      address_line_1 { "Test House" }
      address_line_2 { "Test Street" }
      address_line_3 { "Test Town" }
      address_line_4 { "Test County" }
      postcode { "TE57 1NG" }
      skip_postcode_search { true }
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

    trait :with_itt_academic_year do
      itt_academic_year do
        Journeys::TargetedRetentionIncentivePayments.configuration.current_academic_year - 3
      end
    end

    trait :with_no_eligible_subjects do
      itt_academic_year { Policies::EarlyCareerPayments.current_academic_year - 1 }
    end

    trait :with_teaching_subject_now do
      teaching_subject_now { true }
    end

    trait :with_eligible_itt_subject do
      eligible_itt_subject { "mathematics" }
    end

    trait :with_selected_policy_ecp do
      selected_policy { "EarlyCareerPayments" }
    end

    trait :with_selected_policy_targeted_retention_incentive do
      selected_policy { "TargetedRetentionIncentivePayments" }
    end

    trait :submittable do
      targeted_retention_incentive_eligible
      with_personal_details
      with_address_details
      with_email_details
      provide_mobile_number { false }
      with_bank_details
      with_payroll_gender
      with_teacher_reference_number
    end

    trait :first_targeted_retention_incentive_claim_year do
      academic_year { AcademicYear.new(2022) }
    end

    trait :itt_year_good_for_life_of_targeted_retention_incentive_policy do
      itt_academic_year { Policies::TargetedRetentionIncentivePayments.current_academic_year - 1 }
    end

    # FIXME RL rename this to just eligible
    trait :targeted_retention_incentive_eligible do
      first_targeted_retention_incentive_claim_year
      itt_year_good_for_life_of_targeted_retention_incentive_policy
      current_school_id { create(:school, :targeted_retention_incentive_payments_eligible).id }
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
      teaching_subject_now { true }
      eligible_itt_subject { :mathematics }
      employed_directly { true }
    end

    trait :trainee_teacher do
      nqt_in_academic_year_after_itt { false }
    end

    trait :targeted_retention_incentive_ineligible_itt_subject do
      eligible_itt_subject { :foreign_languages }
    end

    trait :targeted_retention_incentive_ineligible do
      targeted_retention_incentive_eligible
      targeted_retention_incentive_ineligible_school
    end

    trait :targeted_retention_incentive_ineligible_school do
      current_school_id do
        create(:school, :targeted_retention_incentive_payments_ineligible).id
      end
    end

    trait :short_term_supply_teacher do
      employed_as_supply_teacher { true }
      has_entire_term_contract { false }
    end

    trait :long_term_directly_employed_supply_teacher do
      employed_as_supply_teacher { true }
      has_entire_term_contract { true }
      employed_directly { true }
    end

    trait :agency_supply_teacher do
      employed_as_supply_teacher { true }
      employed_directly { false }
    end

    trait :short_term_agency_supply_teacher do
      employed_as_supply_teacher { true }
      has_entire_term_contract { false }
      employed_directly { false }
    end

    trait :sufficient_teaching do
      teaching_subject_now { true }
    end

    trait :insufficient_teaching do
      teaching_subject_now { false }
    end

    trait :relevant_degree do
      eligible_degree_subject { true }
    end

    trait :no_relevant_degree do
      eligible_degree_subject { false }
    end

    trait :targeted_retention_incentive_undetermined do
      targeted_retention_incentive_eligible
      teaching_subject_now { nil }
    end

    trait :not_a_supply_teacher do
      employed_as_supply_teacher { false }
    end
  end
end
