FactoryBot.define do
  factory :payroll_run do
    created_by { "123" }

    transient do
      claims_count { 1 }
      payment_traits { [] }
    end

    after(:create) do |payroll_run, evaluator|
      create_list(:payment, evaluator.claims_count, *evaluator.payment_traits, payroll_run: payroll_run)
    end

    trait :confirmation_report_uploaded do
      confirmation_report_uploaded_by { "some-user-id" }
      payment_traits { %i[with_figures] }
    end
  end
end
