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
    let(:payroll_run) { create(:payroll_run, claims_count: 1) }
    let!(:submitted_claim) { create(:claim, :submitted) }
    let!(:first_unpayrolled_claim) { create(:claim, :approved) }
    let!(:second_unpayrolled_claim) { create(:claim, :approved) }

    it "includes claims that do not belong to a payroll run" do
      expect(PayrollRun.payrollable_claims).to include(first_unpayrolled_claim)
      expect(PayrollRun.payrollable_claims).to include(second_unpayrolled_claim)
    end

    it "does not include claims that belong to a payroll run" do
      expect(PayrollRun.payrollable_claims).not_to include(payroll_run.claims.first)
    end

    it "only includes approved claims" do
      expect(PayrollRun.payrollable_claims).not_to include(submitted_claim)
    end
  end

  describe ".create_with_claims!" do
    let(:claims) { create_list(:claim, 2, :approved) }

    it "creates a payroll run with payments and populates the award_amount" do
      claims[0].eligibility.update(student_loan_repayment_amount: 300)
      claims[1].eligibility.update(student_loan_repayment_amount: 600)

      payroll_run = PayrollRun.create_with_claims!(claims, created_by: "creator-id")

      expect(payroll_run.reload.created_by).to eq("creator-id")
      expect(payroll_run.claims).to match_array(claims)
      expect(claims[0].payment.award_amount).to eq(300)
      expect(claims[1].payment.award_amount).to eq(600)
    end
  end
end
