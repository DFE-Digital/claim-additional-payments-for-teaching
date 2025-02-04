require "rails_helper"

RSpec.describe "Admin views payment spec" do
  around do |example|
    travel_to Date.new(2025, 1, 1) do
      example.run
    end
  end

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :further_education_payments)
    create(:journey_configuration, :levelling_up_premium_payments)
  end

  it "shows the payment details" do
    payroll_run = create(
      :payroll_run,
      created_at: DateTime.new(2025, 1, 1, 12, 0, 0)
    )

    claim_1 = create(
      :claim,
      :approved,
      policy: Policies::FurtherEducationPayments,
      eligibility_attributes: {
        award_amount: 111.11
      }
    )

    personal_details = Payment::PERSONAL_CLAIM_DETAILS_ATTRIBUTES_FORBIDDING_DISCREPANCIES.map do |attr|
      [attr, claim_1.send(attr)]
    end.to_h

    claim_2 = create(
      :claim,
      :approved,
      **personal_details,
      eligibility_attributes: {
        student_loan_repayment_amount: 222.22
      }
    )

    create(:levelling_up_premium_payments_award, award_amount: 9999)

    topup_1 = create(
      :topup,
      award_amount: 333.33,
      claim: create(
        :claim,
        :current_academic_year,
        policy: Policies::LevellingUpPremiumPayments,
        **personal_details
      )
    )

    topup_2 = create(
      :topup,
      award_amount: 444.44,
      claim: create(
        :claim,
        :current_academic_year,
        policy: Policies::LevellingUpPremiumPayments,
        **personal_details
      )
    )

    payment = create(
      :payment,
      payroll_run: payroll_run,
      claims: [claim_1, claim_2, topup_1.claim, topup_2.claim],
      topups: [topup_1, topup_2],
      award_amount: 1111.10 # 111.11 + 222.22 + 333.33 + 444.44
    )

    sign_in_as_service_operator

    visit admin_payment_path(payment)

    expect(page).to have_content("Payment #{payment.id}")
    expect(page).to have_content("£1,111.10")
    expect(page).to have_link(
      "January 2025", href: admin_payroll_run_path(payroll_run)
    )

    expect(page).not_to have_content("Gross value")

    claim_rows = find_all("#claims table tbody tr").to_a

    expect(claim_rows.map(&:text)).to match_array([
      "#{claim_1.reference} Further Education Targeted Retention Incentive £111.11",
      "#{claim_2.reference} Student Loans £222.22"
    ])

    topup_rows = find_all("#topups table tbody tr").to_a

    expect(topup_rows.map(&:text)).to match_array([
      "#{topup_1.claim.reference} School Targeted Retention Incentive £333.33 Aaron Admin",
      "#{topup_2.claim.reference} School Targeted Retention Incentive £444.44 Aaron Admin"
    ])
  end

  it "shows additional payment details if the payment is confirmed" do
    payment = create(:payment, :with_figures, :confirmed, award_amount: 1337.33)

    sign_in_as_service_operator

    visit admin_payment_path(payment)

    payment_rows = find_all("#payment-details table tbody tr").to_a

    expect(payment_rows.map(&:text)).to match_array([
      "Payroll run January 2025",
      "Payment amount £1,337.33",
      "Gross value £1,925.76",
      "NI £160.48",
      "Employers NI £160.48",
      "Student loan repayment £0.00",
      "Tax £267.47",
      "Net pay £1,337.33",
      "Gross pay £1,765.28",
      "Postgraduate loan repayment -",
      "Scheduled payment date 1 January 2025",
      "Confirmed by Aaron Admin"
    ])
  end
end
