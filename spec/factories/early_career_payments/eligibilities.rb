FactoryBot.define do
  factory :early_career_payments_eligibility, class: "EarlyCareerPayments::Eligibility" do
    trait :eligible do
      eligible_now
    end

    # Traits specific to ECP
    trait :eligible_now do
      common_eligible_attributes
      eligible_itt_subject_now
    end

    trait :eligible_now_with_mathematics do
      eligible_now
      eligible_itt_subject { :mathematics }
    end

    trait :ineligible_now_but_eligible_next_year do
      eligible_now_with_mathematics
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) } # this makes it ineligible
    end

    trait :eligible_now_and_again_but_two_years_later do
      eligible_now_with_mathematics
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }
    end

    trait :eligible_next_year_too do
      eligible_now_with_mathematics
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }
    end

    trait :eligible_school do
      # TODO remove fixture dependence
      current_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
    end

    trait :ineligible_school do
      association :current_school, factory: [:school, :early_career_payments_ineligible]
    end

    # Assumes 2022 policy year
    trait :eligible_itt_subject_now do
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }
      eligible_itt_subject { :mathematics }
    end

    # Assumes 2022 policy year
    trait :eligible_itt_subject_later do
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }
      eligible_itt_subject { :mathematics }
    end

    trait :ineligible_itt_subject do
      eligible_itt_subject { :computing }
    end

    # Assumes 2022 policy year
    trait :no_eligible_subjects do
      eligible_now
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2021)) }
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
      current_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
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
