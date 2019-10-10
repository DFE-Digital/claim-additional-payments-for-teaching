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

  describe ".payrollable_claims" do
    let(:payroll_run) { create(:payroll_run) }
    let!(:payrolled_claim) { create(:claim, payroll_run: payroll_run) }
    let!(:submitted_claim) { create(:claim, :submitted) }
    let!(:first_unpayrolled_claim) { create(:claim, :approved) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved) }

    it "includes claims that do not belong to a payroll run" do
      expect(PayrollRun.payrollable_claims).to include(first_unpayrolled_claim)
      expect(PayrollRun.payrollable_claims).to include(second_unpayrolled_claim)
    end

    it "does not include claims that belong to a payroll run" do
      expect(PayrollRun.payrollable_claims).not_to include(payrolled_claim)
    end

    it "only includes approved claims" do
      expect(PayrollRun.payrollable_claims).not_to include(submitted_claim)
    end
  end
end
