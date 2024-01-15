require "rails_helper"

RSpec.describe ClaimStudentLoanDetailsUpdater do
  let(:updater) { described_class.new(claim) }
  let(:claim) { create(:claim) }

  describe ".call" do
    let(:updater_mock) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).with(claim).and_return(updater_mock)
    end

    it "invokes the update_claim_with_latest_data instance method" do
      expect(updater_mock).to receive(:update_claim_with_latest_data)
      described_class.call(claim)
    end
  end

  describe "#update_claim_with_latest_data" do
    subject(:call) { updater.update_claim_with_latest_data }

    context "when no existing SLC data is found for the claimant" do
      it "returns true" do
        expect(call).to eq(true)
      end

      it "updates the claim with no student plan and zero repayment total" do
        expect { call }.to change { claim.has_student_loan }.to(false)
          .and change { claim.student_loan_plan }.to(Claim::NO_STUDENT_LOAN)
          .and change { claim.eligibility.student_loan_repayment_amount }.to(0)
      end
    end

    context "when existing SLC data is found for the claimant" do
      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1, amount: 50)
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 2, amount: 60)
      end

      it "returns true" do
        expect(call).to eq(true)
      end

      it "updates the claim with the student plans and repayment total" do
        expect { call }.to change { claim.has_student_loan }.to(true)
          .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1_AND_2)
          .and change { claim.eligibility.student_loan_repayment_amount }.to(110)
      end
    end
  end
end
