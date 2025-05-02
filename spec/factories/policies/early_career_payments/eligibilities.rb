FactoryBot.define do
  factory :early_career_payments_eligibility, class: "Policies::EarlyCareerPayments::Eligibility" do
    award_amount { 5000.0 }

    itt_academic_year do
      AcademicYear.current - 3
    end

    trait :eligible do
      teacher_reference_number { generate(:teacher_reference_number) }
      eligible_now
    end

    # Traits specific to ECP
    trait :eligible_now do
      common_eligible_attributes
      induction_completed
      eligible_itt_subject_now
    end

    trait :eligible_now_with_mathematics do
      eligible_now
      eligible_itt_subject { :mathematics }
    end

    trait :ineligible_now_but_eligible_next_year do
      eligible_now_with_mathematics
      itt_academic_year { AcademicYear.current - 4 } # this makes it ineligible
    end

    trait :eligible_now_and_again_but_two_years_later do
      eligible_now_with_mathematics
      itt_academic_year { AcademicYear.current - 3 }
    end

    trait :eligible_school_ecp_only do
      association :current_school, factory: [:school, :early_career_payments_eligible, :targeted_retention_incentive_payments_ineligible]
    end

    trait :eligible_school_ecp_and_targeted_retention_incentive do
      association :current_school, factory: [:school, :combined_journey_eligibile_for_all]
    end

    trait :eligible_school do
      association :current_school, factory: [:school, :early_career_payments_eligible]
    end

    trait :ineligible_school do
      association :current_school, factory: [:school, :early_career_payments_ineligible]
    end

    trait :eligible_itt_subject_now do
      itt_academic_year { AcademicYear.current - 3 }
      eligible_itt_subject { :mathematics }
    end

    trait :eligible_itt_subject_later do
      itt_academic_year { Policies::EarlyCareerPayments.current_academic_year - 4 }
      eligible_itt_subject { :mathematics }
    end

    trait :ineligible_itt_subject do
      eligible_itt_subject { :computing }
    end

    trait :no_eligible_subjects do
      eligible_now
      itt_academic_year { Policies::EarlyCareerPayments.current_academic_year - 1 }
    end

    trait :ineligible do
      eligible_now
      ineligible_itt_subject
    end

    trait :eligible_later do
      eligible_now
      eligible_itt_subject_later
    end

    # TODO want to delete this but it's used by a feature spec
    trait :ineligible_feature do
      nqt_in_academic_year_after_itt { true }
      eligible_school
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
    end

    # Traits common to both ECP and Targeted Retention Incentive
    trait :common_eligible_attributes do
      school_somewhere_else { nil }
      eligible_school
      newly_qualified_teacher
      not_a_supply_teacher
      good_performance
      qualification { :postgraduate_itt }
      sufficient_teaching
    end

    trait :newly_qualified_teacher do
      nqt_in_academic_year_after_itt { true }
    end

    trait :induction_completed do
      induction_completed { true }
    end

    trait :induction_not_completed do
      induction_completed { false }
    end

    trait :not_a_supply_teacher do
      employed_as_supply_teacher { false }
    end

    trait :supply_teacher do
      employed_as_supply_teacher { true }
    end

    trait :short_term_supply_teacher do
      supply_teacher
      has_entire_term_contract { false }
    end

    trait :agency_supply_teacher do
      supply_teacher
      employed_directly { false }
    end

    trait :short_term_agency_supply_teacher do
      supply_teacher
      has_entire_term_contract { false }
      employed_directly { false }
    end

    trait :long_term_directly_employed_supply_teacher do
      supply_teacher
      has_entire_term_contract { true }
      employed_directly { true }
    end

    trait :good_performance do
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
    end

    trait :sufficient_teaching do
      teaching_subject_now { true }
    end

    trait :insufficient_teaching do
      teaching_subject_now { false }
    end

    trait :trainee_teacher do
      nqt_in_academic_year_after_itt { false }
    end

    trait :ineligible do
      eligible_now
      ineligible_school
    end

    trait :undetermined do
      eligible_now
      teaching_subject_now { nil }
    end
  end
end
