require "rails_helper"

RSpec.describe StudentLoanPlanCheckJob do
  subject(:perform_job) { described_class.new.perform }

  let!(:claim) { create(:claim, claim_status, academic_year:, policy: LevellingUpPremiumPayments) }
  let(:claim_status) { :submitted }

  let(:academic_year) { journey_configuration.current_academic_year }
  let(:journey_configuration) { create(:journey_configuration, :additional_payments) }

  describe "#perform" do
    before do
      allow(ClaimStudentLoanDetailsUpdater).to receive(:call)
    end

    shared_examples :skip_check do
      before do
        allow(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).to receive(:new)
      end

      it "excludes the claim from the check", :aggregate_failures do
        expect(ClaimStudentLoanDetailsUpdater).not_to receive(:call).with(claim)
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).not_to receive(:new).with(claim: claim)
        perform_job
      end
    end

    context "when the previous student loan plan check was run manually" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: nil, manual: true) }

      include_examples :skip_check
    end

    context "when a claim is not awaiting decision" do
      let(:claim_status) { :approved }

      include_examples :skip_check
    end

    context "when a claim was submitted using SLC data" do
      before do
        claim.update!(submitted_using_slc_data: true)
      end

      include_examples :skip_check
    end

    context "when a claim was submitted using the student loan questions" do
      before do
        claim.update!(submitted_using_slc_data: nil)
      end

      include_examples :skip_check
    end

    context "when the student loan plan check did not run before" do
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

    context "when the previous student loan plan check outcome was NO DATA" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: nil, manual: false) }

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

    context "when the previous student loan plan check outcome was FAILED" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: :none, passed: false, manual: false) }

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

    context "when the previous student loan plan check outcome was PASSED" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: :all, manual: false) }

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
