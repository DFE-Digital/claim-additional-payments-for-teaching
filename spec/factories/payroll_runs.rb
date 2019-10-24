FactoryBot.define do
  factory :payroll_run do
    created_by { "123" }

    transient do
      claims_count { 1 }
    end

    after(:create) do |payroll_run, evaluator|
      create_list(:payment, evaluator.claims_count, payroll_run: payroll_run)
    end
  end
end
