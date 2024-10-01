require "rails_helper"

RSpec.describe StudentLoanPlanCheckJob do
  subject(:perform_job) { described_class.new.perform }

  before do
    create(:journey_configuration, :further_education_payments)
  end

  let!(:claim) { create(:claim, claim_status, academic_year:, policy: Policies::LevellingUpPremiumPayments) }
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
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim)
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
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim)
        perform_job
      end

      it "calls the student loan plan claim verifier" do
        expect(AutomatedChecks::ClaimVerifiers::StudentLoanPlan).to receive(:new).with(claim: claim).and_return(student_loan_plan_claim_verifier)
        perform_job
      end
    end

    context "when the student loan plan check did not run before" do
      it "updates the student loan details" do
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim)
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
        expect(ClaimStudentLoanDetailsUpdater).to receive(:call).with(claim)
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
  end
end
