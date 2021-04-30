FactoryBot.define do
  factory :early_career_payments_eligibility, class: "EarlyCareerPayments::Eligibility" do
    trait :eligible do
      nqt_in_academic_year_after_itt { true }
      employed_as_supply_teacher { false }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
      pgitt_or_ugitt_course { :postgraduate }
      eligible_itt_subject { 2 }
      teaching_subject_now { true }
      itt_academic_year { "2020_2021" }
      postgraduate_masters_loan { true }
    end
  end
end
