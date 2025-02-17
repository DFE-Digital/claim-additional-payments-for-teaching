FactoryBot.define do
  factory :payment do
    transient do
      claim_policies { [Policies::StudentLoans] }
    end

    claims do
      personal_details = attributes_for(
        :claim,
        :random_personal_details,
        :with_bank_details
      ).except(:reference).merge(
        eligibility_attributes: {
          teacher_reference_number: generate(:teacher_reference_number)
        }
      )
      claim_policies.map do |policy|
        association(:claim, :approved, personal_details.merge(policy: policy))
      end
    end

    association(:payroll_run, factory: :payroll_run)

    award_amount { claims.map(&:award_amount).compact.sum }

    trait :with_figures do
      # This is a rough approximation of the "grossing up" done by DfE Payroll. It
      # gives realistic-ish numbers.
      gross_value { gross_pay + employers_national_insurance }
      gross_pay { award_amount + tax + national_insurance }
      national_insurance { award_amount * 0.12 }
      employers_national_insurance { award_amount * 0.12 }
      student_loan_repayment { 0 }
      tax { award_amount * 0.2 }
      net_pay { award_amount }
    end

    trait :confirmed do
      scheduled_payment_date { Date.today }

      after(:create) do |payment, _evaluator|
        create(:payment_confirmation, payments: [payment], payroll_run: payment.payroll_run)
      end
    end
  end
end
