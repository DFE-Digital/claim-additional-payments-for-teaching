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

    trait :with_itt_academic_year do
      itt_academic_year do
        Journeys::AdditionalPaymentsForTeaching.configuration.current_academic_year - 3
      end
    end

    trait :with_teaching_subject_now do
      teaching_subject_now { true }
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
      with_itt_academic_year
      with_teaching_subject_now
    end

    trait :first_lup_claim_year do
      academic_year { AcademicYear.new(2022) }
    end

    trait :itt_year_good_for_life_of_lup_policy do
      itt_academic_year { Journeys.for_policy(Policies::LevellingUpPremiumPayments).configuration.current_academic_year - 1 }
    end

    trait :lup_eligible do
      first_lup_claim_year
      itt_year_good_for_life_of_lup_policy
      current_school_id { create(:school, :levelling_up_premium_payments_eligible).id }
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
      teaching_subject_now { true }
      eligible_itt_subject { :mathematics }
      employed_directly { true }
    end

    trait :ecp_eligible do
      school_somewhere_else { nil }
      current_school_id { create(:school, :early_career_payments_eligible).id }
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
      induction_completed { true }
      teaching_subject_now { true }
      itt_academic_year { Journeys.for_policy(Policies::EarlyCareerPayments).configuration.current_academic_year - 3 }
      eligible_itt_subject { :mathematics }
      employed_directly { true }
    end

    trait :ecp_and_lup_eligible do
      lup_eligible
      ecp_eligible
      current_school_id do
        create(
          :school,
          :early_career_payments_eligible,
          :levelling_up_premium_payments_eligible
        ).id
      end
    end

    trait :trainee_teacher do
      nqt_in_academic_year_after_itt { false }
    end

    trait :ecp_eligible_itt_subject_later do
      itt_academic_year { Journeys.for_policy(Policies::EarlyCareerPayments).configuration.current_academic_year - 4 }
      eligible_itt_subject { :mathematics }
    end

    trait :ecp_eligible_later do
      ecp_eligible
      ecp_eligible_itt_subject_later
    end

    trait :ecp_ineligible_itt_subject do
      eligible_itt_subject { :computing }
    end

    trait :lup_ineligible_itt_subject do
      eligible_itt_subject { :foreign_languages }
    end

    trait :ecp_ineligible do
      ecp_eligible
      ecp_ineligible_itt_subject
    end

    trait :lup_ineligible do
      lup_eligible
      current_school_id do
        create(:school, :levelling_up_premium_payments_ineligible).id
      end
    end

    trait :short_term_supply_teacher do
      employed_as_supply_teacher { true }
      has_entire_term_contract { false }
    end

    trait :agency_supply_teacher do
      employed_as_supply_teacher { true }
      employed_directly { false }
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

    trait :eligible_school_ecp_and_lup do
      current_school_id do
        create(:school, :combined_journey_eligibile_for_all).id
      end
    end

    trait :ecp_undetermined do
      ecp_eligible
      teaching_subject_now { nil }
    end

    trait :lup_undetermined do
      lup_eligible
      teaching_subject_now { nil }
    end

    trait :ecp_and_lup_undetermined do
      ecp_and_lup_eligible
      teaching_subject_now { nil }
    end
  end
end
