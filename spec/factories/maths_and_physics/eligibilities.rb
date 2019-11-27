FactoryBot.define do
  factory :maths_and_physics_eligibility, class: "MathsAndPhysics::Eligibility" do
    trait :eligible do
      teaching_maths_or_physics { true }
      current_school { School.find(ActiveRecord::FixtureSet.identify(:penistone_grammar_school, :uuid)) }
      initial_teacher_training_specialised_in_maths_or_physics { true }
      initial_teacher_training_subject { :maths }
      qts_award_year { "on_or_after_september_2014" }
      employed_as_supply_teacher { false }
      subject_to_disciplinary_action { false }
      subject_to_formal_performance_action { false }
    end
  end
end
