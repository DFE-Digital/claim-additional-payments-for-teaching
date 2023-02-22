FactoryBot.define do
  factory :simple_policy_payments_eligibility, class: "SimplePolicyPayments::Eligibility" do
    trait :eligible do
      association :current_school, factory: [:school, :simple_policy_payments_eligible]
    end
  end
end
