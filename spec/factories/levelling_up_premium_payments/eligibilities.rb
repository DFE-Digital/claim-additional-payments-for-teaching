FactoryBot.define do
  factory :levelling_up_premium_payments_eligibility, class: "LevellingUpPremiumPayments::Eligibility" do
    trait :eligible do
      newly_qualified_teacher
      association :current_school, factory: [:school, :levelling_up_premium_payments_eligible]
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
      eligible_itt_subject { :mathematics }
      teaching_subject_now { true }
      # TODO: the year should be dynamic based on the policy configuration current academic year, otherwise it might fail when the year increments
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2019)) }
    end

    trait :ineligible do
      eligible
      association :current_school, factory: [:school, :levelling_up_premium_payments_ineligible]
    end

    trait :trainee_teacher do
      nqt_in_academic_year_after_itt { false }
    end

    trait :newly_qualified_teacher do
      nqt_in_academic_year_after_itt { true }
    end
  end
end
