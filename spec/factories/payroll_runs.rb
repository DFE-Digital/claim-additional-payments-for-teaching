FactoryBot.define do
  factory :payroll_run do
    created_by { "123" }

    transient do
      claims_counts { {StudentLoans => 1} }
      payment_traits { [] }
    end

    after(:create) do |payroll_run, evaluator|
      evaluator.claims_counts.each do |policy, count|
        create_list(:payment, count, *evaluator.payment_traits, claim_policy: policy, payroll_run: payroll_run)
      end
    end

    trait :confirmation_report_uploaded do
      confirmation_report_uploaded_by { "some-user-id" }
      payment_traits { %i[with_figures] }
    end
  end
end
