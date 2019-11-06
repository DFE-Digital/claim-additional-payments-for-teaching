FactoryBot.define do
  factory :maths_and_physics_eligibility, class: "MathsAndPhysics::Eligibility" do
    trait :eligible do
      teaching_maths_or_physics { true }
    end
  end
end
