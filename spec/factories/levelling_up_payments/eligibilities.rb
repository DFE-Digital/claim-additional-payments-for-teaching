FactoryBot.define do
  factory :levelling_up_payments_eligibility, class: "LevellingUpPayments::Eligibility" do
    trait :eligible do
      association :current_school, :levelling_up_payments_eligible, factory: :school
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
      eligible_itt_subject { :mathematics }
      teaching_subject_now { true }
      itt_academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2018)) }
    end

    trait :ineligible_feature do
      association :current_school, :levelling_up_payments_ineligible, factory: :school
    end
  end
end
