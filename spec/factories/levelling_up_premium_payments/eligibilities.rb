FactoryBot.define do
  factory :levelling_up_premium_payments_eligibility, class: "LevellingUpPremiumPayments::Eligibility" do
    trait :eligible do # TODO rename
      eligible_now
    end

    # Traits specific to LUP
    trait :eligible_now do
      common_eligible_attributes
      itt_year_good_for_life_of_lup_policy
      lup_itt_subject
    end

    trait :eligible_next_year_too do
      eligible_now
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }
      eligible_itt_subject { :mathematics }
    end

    trait :eligible_school do
      association :current_school, factory: [:school, :levelling_up_premium_payments_eligible]
    end

    trait :ineligible_school do
      association :current_school, factory: [:school, :levelling_up_premium_payments_ineligible]
    end

    trait :itt_year_good_for_life_of_lup_policy do
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }
    end

    trait :lup_itt_subject do
      eligible_itt_subject { :mathematics }
    end

    trait :ineligible_itt_subject do
      eligible_itt_subject { :foreign_languages }
    end

    trait :relevant_degree do
      eligible_degree_subject { true }
    end

    trait :no_relevant_degree do
      eligible_degree_subject { false }
    end

    trait :eligible_later do
      # TODO any_future_policy_years?
      eligible_school
      trainee_teacher
      lup_itt_subject
    end

    # Traits common to both ECP and LUP
    trait :common_eligible_attributes do
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
