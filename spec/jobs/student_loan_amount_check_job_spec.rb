require "rails_helper"

RSpec.describe StudentLoanAmountCheckJob do
  subject(:perform_job) { described_class.new.perform }

  let(:claim) { create(:claim, :submitted, academic_year: academic_year, policy: Policies::StudentLoans) }
  let(:academic_year) { journey_configuration.current_academic_year }
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  describe "#perform" do
    before do
      allow(ClaimStudentLoanDetailsUpdater).to receive(:call)
    end

    context "when the student loan amount check did not run before" do
      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim)
        perform_job
      end

      it "runs the task" do
        expect { perform_job }
          .to change { claim.reload.notes.count }
          .and change { claim.tasks.count }
      end
    end

    context "when the previous student loan amount check outcome was NO DATA" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_amount", claim_verifier_match: nil, manual: false) }

      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim)
        perform_job
      end

      it "re-runs the task" do
        expect { perform_job }
          .to change { claim.reload.notes.count }
          .and change { claim.tasks.last.updated_at }
          .and not_change { claim.reload.tasks.count }
      end
    end

    context "when the previous student loan amount check outcome was FAIL" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_amount", claim_verifier_match: :none, passed: false, manual: false) }

      it "does not update the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).not_to receive(:call)
        perform_job
      end

      it "does not re-run the task" do
        expect { perform_job }
          .to not_change { claim.reload.notes.count }
          .and not_change { claim.tasks.last.updated_at }
          .and not_change { claim.reload.tasks.count }
      end
    end

    context "when the previous student loan amount check outcome was PASS" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_amount", claim_verifier_match: :all, manual: false) }

      it "does not update the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).not_to receive(:call)
        perform_job
      end

      it "does not re-run the task" do
        expect { perform_job }
          .to not_change { claim.reload.notes.count }
          .and not_change { claim.tasks.last.updated_at }
          .and not_change { claim.reload.tasks.count }
      end
    end
  end
end
