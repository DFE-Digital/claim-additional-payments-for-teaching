require "rails_helper"

RSpec.describe ClaimStudentLoanDetailsUpdater do
  let(:updater) { described_class.new(claim) }
  let(:claim) { create(:claim, policy:) }
  let(:policy) { Policies::StudentLoans }

  describe ".call" do
    let(:updater_mock) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).with(claim).and_return(updater_mock)
    end

    it "invokes the `update_claim_with_latest_data` instance method" do
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

      context "when the policy is StudentLoans" do
        let(:policy) { Policies::StudentLoans }

        it "does not update the claim student plan and zero repayment total" do
          expect { call }.not_to change { claim.reload.has_student_loan }
        end

        it "keeps the `submitted_using_slc_data` flag to `false` (default)" do
          expect { call }.not_to change { claim.submitted_using_slc_data }.from(false)
        end
      end

      [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments, Policies::FurtherEducationPayments].each do |policy|
        context "when the policy is #{policy}" do
          let(:policy) { policy }

          it "does not update the claim" do
            expect { call }.not_to change { claim.reload }
          end
        end
      end
    end

    context "when SLC data is found with student loan information for the claimant" do
      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1, amount: 50)
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 2, amount: 60)
      end

      it "returns true" do
        expect(call).to eq(true)
      end

      context "when the policy is StudentLoans" do
        it "updates the claim with the student plan and the repayment total" do
          expect { call }.to change { claim.reload.has_student_loan }.to(true)
            .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1_AND_2)
            .and change { claim.eligibility.student_loan_repayment_amount }.to(110)
        end
      end

      [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments, Policies::FurtherEducationPayments].each do |policy|
        context "when the policy is #{policy}" do
          let(:policy) { policy }

          it "updates the claim with the student plan only" do
            expect { call }.to change { claim.reload.has_student_loan }.to(true)
              .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1_AND_2)
          end
        end
      end
    end

    context "when SLC data is found with no student loan information for the claimant" do
      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: nil, amount: nil)
      end

      it "returns true" do
        expect(call).to eq(true)
      end

      context "when the policy is StudentLoans" do
        it "updates the claim with the student plan and the repayment total" do
          expect { call }.to change { claim.reload.has_student_loan }.to(false)
            .and change { claim.student_loan_plan }.to(Claim::NO_STUDENT_LOAN)
            .and change { claim.eligibility.student_loan_repayment_amount }.to(0)
        end
      end

      [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments].each do |policy|
        context "when the policy is #{policy}" do
          let(:policy) { policy }

          it "updates the claim with the student plan only" do
            expect { call }.to change { claim.reload.has_student_loan }.to(false)
              .and change { claim.student_loan_plan }.to(Claim::NO_STUDENT_LOAN)
          end
        end
      end
    end

    context "when updating a claim after submission" do
      let(:claim) { create(:claim, :submitted, :with_no_student_loan, policy:) }

      before do
        create(:student_loans_data, nino: claim.national_insurance_number, date_of_birth: claim.date_of_birth, plan_type_of_deduction: 1, amount: 50)
      end

      it "updates the claim with the student plan and the repayment total" do
        expect { call }.to change { claim.reload.has_student_loan }.to(true)
          .and change { claim.student_loan_plan }.to(StudentLoan::PLAN_1)
          .and change { claim.eligibility.student_loan_repayment_amount }.to(50)
      end

      it "does not change the `submitted_using_slc_data` flag" do
        expect { call }.to not_change { claim.submitted_using_slc_data }
      end
    end
  end
end
