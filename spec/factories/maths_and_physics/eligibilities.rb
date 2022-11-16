FactoryBot.define do
  factory :maths_and_physics_eligibility, class: "MathsAndPhysics::Eligibility" do
    trait :eligible do
      association :current_school, factory: [:school, :maths_and_physics_eligible]
      teaching_maths_or_physics { true }
      initial_teacher_training_subject { :maths }
      qts_award_year { :on_or_after_cut_off_date }
      employed_as_supply_teacher { false }
      subject_to_disciplinary_action { false }
      subject_to_formal_performance_action { false }
    end
  end
end
