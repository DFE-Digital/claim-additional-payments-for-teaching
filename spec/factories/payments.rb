FactoryBot.define do
  factory :payment do
    transient do
      claim_policies { [StudentLoans] }
      scheduled_payment_date { Date.today }
    end

    claims do
      personal_details = {
        national_insurance_number: generate(:national_insurance_number),
        teacher_reference_number: generate(:teacher_reference_number),
        email_address: "email@example.com",
        bank_sort_code: "220011",
        bank_account_number: "12345678",
      }
      claim_policies.map do |policy|
        association(:claim, :approved, personal_details.merge(policy: policy))
      end
    end
    association(:payroll_run, factory: :payroll_run)

    award_amount { claims.sum(&:award_amount) }

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

      payroll_run do
        create(:payroll_run, :confirmation_report_uploaded, scheduled_payment_date: scheduled_payment_date)
      end
    end
  end
end
