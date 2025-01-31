require "rails_helper"

RSpec.describe StudentLoanPlanCheckJob do
  let(:admin) { create(:dfe_signin_user) }
  subject(:perform_job) { described_class.new.perform(admin) }

  before do
    create(:journey_configuration, :further_education_payments)
    create(:journey_configuration, :early_years_payment_provider_start)
  end

  let!(:claim) { create(:claim, claim_status, academic_year:, policy: Policies::TargetedRetentionIncentivePayments) }
  let(:claim_status) { :submitted }

  let(:academic_year) { journey_configuration.current_academic_year }
  let(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let(:student_loan_plan_claim_verifier) { instance_double(AutomatedChecks::ClaimVerifiers::StudentLoanPlan, perform: true) }

  describe "#perform" do
    shared_examples :student_loan_plan_claim_verifier_not_called do
      it "excludes the claim from the check", :aggregate_failures do
        expect(ClaimStudentLoanDetailsUpdater).not_to receive(:call)
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).not_to receive(:new)
        perform_job
      end
    end

    it "includes all applicable policies" do
      expect(StudentLoanPlanCheckJob::APPLICABLE_POLICIES).to eq [
        Policies::EarlyCareerPayments,
        Policies::TargetedRetentionIncentivePayments,
        Policies::FurtherEducationPayments,
        Policies::EarlyYearsPayments
      ]
    end

    context "when the previous student loan plan check was run manually" do # not sure it's possible to do this any more
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: nil, manual: true) }

      include_examples :student_loan_plan_claim_verifier_not_called
    end

    context "when a claim is not awaiting decision" do
      let(:claim_status) { :approved }

      include_examples :student_loan_plan_claim_verifier_not_called
    end

    context "when a claim was submitted using SLC data" do
      before do
        claim.update!(submitted_using_slc_data: true)
      end

      include_examples :student_loan_plan_claim_verifier_not_called
    end

    context "when a claim was submitted with no SLC data available" do
      before do
        claim.update!(submitted_using_slc_data: false)
      end

      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim, admin)
        perform_job
      end

      it "calls the student loan plan claim verifier" do
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).to receive(:new).with(claim: claim).and_return(student_loan_plan_claim_verifier)
        perform_job
      end
    end

    # this will only happen for FE claims submitted before LUPEYALPHA-1010 was merged
    context "when a claim was submitted with submitted_using_slc_data: nil" do
      before do
        claim.update!(submitted_using_slc_data: nil)
      end

      let(:claim) { create(:claim, claim_status, academic_year:, policy: Policies::FurtherEducationPayments) }

      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim, admin)
        perform_job
      end

      it "calls the student loan plan claim verifier" do
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).to receive(:new).with(claim: claim).and_return(student_loan_plan_claim_verifier)
        perform_job
      end
    end

    context "when the student loan plan check did not run before" do
      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim, admin)
        perform_job
      end

      it "calls the student loan plan claim verifier" do
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).to receive(:new).with(claim: claim).and_return(student_loan_plan_claim_verifier)
        perform_job
      end
    end

    context "when the previous student loan plan check outcome was NO DATA" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: nil, manual: false) }

      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim, admin)
        perform_job
      end

      it "calls the student loan plan claim verifier" do
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).to receive(:new).with(claim: claim).and_return(student_loan_plan_claim_verifier)
        perform_job
      end
    end

    context "when the previous student loan plan check outcome was FAILED" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: :none, passed: false, manual: false) }

      include_examples :student_loan_plan_claim_verifier_not_called
    end

    context "when the previous student loan plan check outcome was PASSED" do
      let!(:previous_task) { create(:task, claim: claim, name: "student_loan_plan", claim_verifier_match: :all, manual: false) }

      include_examples :student_loan_plan_claim_verifier_not_called
    end

    context "when an error occurs while updating" do
      let(:exception) { ActiveRecord::RecordInvalid }

      before do
        create(
          :student_loans_data,
          claim_reference: claim.reference,
          nino: claim.national_insurance_number,
          date_of_birth: claim.date_of_birth,
          plan_type_of_deduction: 2
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
          .and not_change { claim.tasks.count }
          .and not_change { claim.notes.count }
      end
    end
  end
end
