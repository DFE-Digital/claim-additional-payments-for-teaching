FactoryBot.define do
  factory :payroll_run do
    association :created_by, factory: :dfe_signin_user
    association :downloaded_by, factory: :dfe_signin_user

    transient do
      # The claim_counts attribute provides a convenient way to create a
      # payroll run with associated payment objects and associated claim
      # objects, each of whose policy can be specified.
      #
      # You should pass a Hash. For example:
      # { StudentLoans => 10, MathsAndPhysics => 15, [MathsAndPhysics, StudentLoans] => 5 }
      #
      # This will create a payroll run with:
      # - 10 payments each of which has a single StudentLoans claim;
      # - 15 payments each of which has a single MathsAndPhysics claim;
      # - 5 payments each of which has two claims: one for StudentLoans and one for MathsAndPhysics.
      claims_counts { {StudentLoans => 0} }
      payment_traits { [] }
    end

    after(:create) do |payroll_run, evaluator|
      evaluator.claims_counts.each do |policies, count|
        policies = Array(policies)
        create_list(:payment, count, *evaluator.payment_traits, claim_policies: policies, payroll_run: payroll_run)
      end
    end

    trait :confirmation_report_uploaded do
      confirmation_report_uploaded_by { "some-user-id" }
      payment_traits { %i[with_figures] }
    end
  end
end
