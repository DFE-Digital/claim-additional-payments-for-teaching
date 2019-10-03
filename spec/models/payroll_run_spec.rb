require "rails_helper"

RSpec.describe PayrollRun, type: :model do
  describe "#total_award_amount" do
    it "returns the sum of the award amounts of its claims" do
      claim_1 = build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 1500))
      claim_2 = build(:claim, :approved, eligibility: build(:student_loans_eligibility, :eligible, student_loan_repayment_amount: 2000))

      payroll_run = PayrollRun.new(claims: [claim_1, claim_2])

      expect(payroll_run.total_award_amount).to eq(3500)
    end
  end
end
