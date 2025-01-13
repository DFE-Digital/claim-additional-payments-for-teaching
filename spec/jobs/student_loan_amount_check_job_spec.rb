require "rails_helper"

RSpec.describe StudentLoanAmountCheckJob do
  let(:admin) { create(:dfe_signin_user) }
  subject(:perform_job) { described_class.new.perform(admin) }

  let!(:claim) { create(:claim, claim_status, academic_year:, policy: Policies::StudentLoans) }
  let(:claim_status) { :submitted }

  let(:academic_year) { journey_configuration.current_academic_year }
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }

  describe "#perform" do
    context "without error" do
      before do
        allow(ClaimStudentLoanDetailsUpdater).to receive(:call)
      end

      shared_examples :skip_check do
        before do
          allow(AutomatedChecks::ClaimVerifiers::StudentLoanAmount).to receive(:new)
        end

        it "excludes the claim from the check", :aggregate_failures do
          expect(ClaimStudentLoanDetailsUpdater).not_to receive(:call).with(claim, admin)
          expect(AutomatedChecks::ClaimVerifiers::StudentLoanAmount).not_to receive(:new).with(claim: claim)
          perform_job
        end
      end

      context "when the previous student loan amount check was run manually" do
        let!(:previous_task) { create(:task, claim: claim, name: "student_loan_amount", claim_verifier_match: nil, manual: true) }

        include_examples :skip_check
      end

      context "when a claim is not awaiting decision" do
        let(:claim_status) { :approved }

        include_examples :skip_check
      end

      context "when a claim was submitted using the student loan questions" do
        before do
          claim.update!(submitted_using_slc_data: nil)
        end

        include_examples :skip_check
      end

      context "when the student loan amount check did not run before" do
        it "updates the student loan details" do
          expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim, admin)
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
          expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim, admin)
          perform_job
        end

        it "re-runs the task" do
          expect { perform_job }
            .to change { claim.reload.notes.count }
            .and change { claim.tasks.last.updated_at }
            .and not_change { claim.reload.tasks.count }
        end
      end

      context "when the previous student loan amount check outcome was FAILED" do
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

      context "when the previous student loan amount check outcome was PASSED" do
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

    context "when there's an error" do
      let(:exception) { ActiveRecord::RecordInvalid }

      before do
        create(
          :student_loans_data,
          claim_reference: claim.reference,
          nino: claim.national_insurance_number,
          date_of_birth: claim.date_of_birth
        )
        allow_any_instance_of(Claim).to receive(:save) { raise(exception) }
        allow(Rollbar).to receive(:error)
      end

      it "suppresses the exception" do
        expect { perform_job }.not_to raise_error
      end

      it "logs the exception" do
        perform_job

        expect(Rollbar).to have_received(:error).with(exception)
      end

      it "does not update the student loan details or create a task or note" do
        expect { perform_job }.to not_change { claim.student_loan_plan }
          .and not_change { claim.eligibility.student_loan_repayment_amount }
          .and not_change { claim.tasks.count }
          .and not_change { claim.notes.count }
      end
    end
  end
end
