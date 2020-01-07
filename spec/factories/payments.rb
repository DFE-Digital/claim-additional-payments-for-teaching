FactoryBot.define do
  factory :payment do
    transient do
      claim_policies { [StudentLoans] }
    end

    claims do
      claim_policies.map do |policy|
        association(:claim, :approved, policy: policy)
      end
    end
    association(:payroll_run, factory: :payroll_run)

    award_amount { claim.award_amount }

    trait :with_figures do
      # This is a rough approximation of the "grossing up" done by Cantium. It
      # gives realistic-ish numbers.
      gross_value { gross_pay + employers_national_insurance }
      gross_pay { award_amount + tax + national_insurance }
      national_insurance { award_amount * 0.12 }
      employers_national_insurance { award_amount * 0.12 }
      student_loan_repayment { 0 }
      tax { award_amount * 0.2 }
      net_pay { award_amount }
    end
  end
end
