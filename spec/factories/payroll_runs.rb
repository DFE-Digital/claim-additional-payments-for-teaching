FactoryBot.define do
  factory :payroll_run do
    association :created_by, factory: :dfe_signin_user
    association :downloaded_by, factory: :dfe_signin_user

    status { :complete }

    transient do
      # The claim_counts attribute provides a convenient way to create a
      # payroll run with associated payment objects and associated claim
      # objects, each of whose policy can be specified.
      #
      # You should pass a Hash. For example:
      # { Policies::StudentLoans => 10, Policies::EarlyCareerPayments => 15, [Policies::EarlyCareerPayments, Policies::StudentLoans] => 5 }
      #
      # This will create a payroll run with:
      # - 10 payments each of which has a single StudentLoans claim;
      # - 15 payments each of which has a single EarlyCareerPayments claim;
      # - 5 payments each of which has two claims: one for StudentLoans and one for EarlyCareerPayments.
      claims_counts { {Policies::StudentLoans => 0} }
      payment_traits { [] }
      batch_size { 2 }
      confirmed_batches { nil }
    end

    after(:create) do |payroll_run, evaluator|
      evaluator.claims_counts.each do |policies, count|
        policies = Array(policies)
        create_list(:payment, count, *evaluator.payment_traits, claim_policies: policies, payroll_run: payroll_run)
      end
    end

    trait :confirmation_report_uploaded do
      association :confirmation_report_uploaded_by, factory: :dfe_signin_user
      scheduled_payment_date { Date.today }
      payment_traits { %i[with_figures] }
    end

    trait :with_confirmations do
      payment_traits { %i[with_figures] }

      after(:create) do |payroll_run, evaluator|
        payroll_run.payments.ordered.in_batches(of: evaluator.batch_size).each.with_index(1) do |batch, num|
          break if evaluator.confirmed_batches && num > evaluator.confirmed_batches
          create(:payment_confirmation, payments: batch, payroll_run: payroll_run)
        end
      end
    end

    trait :with_payments do
      transient do
        count { 0 }
      end

      payments { build_list(:payment, count) }
    end
  end
end
