FactoryBot.define do
  factory :early_career_payments_eligibility, class: "Policies::EarlyCareerPayments::Eligibility" do
    award_amount { 5000.0 }

    itt_academic_year do
      AcademicYear.current - 3
    end

    trait :eligible do
      teacher_reference_number { generate(:teacher_reference_number) }
      school_somewhere_else { nil }
      association :current_school, factory: [:school, :early_career_payments_eligible]
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      qualification { :postgraduate_itt }
      teaching_subject_now { true }
      induction_completed { true }
      itt_academic_year { AcademicYear.current - 3 }
      eligible_itt_subject { :mathematics }
    end
  end
end
