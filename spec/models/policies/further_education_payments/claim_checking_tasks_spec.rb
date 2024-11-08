require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::ClaimCheckingTasks do
  describe "#applicable_task_names" do
    subject { described_class.new(claim).applicable_task_names }

    let(:payroll_gender) { "male" }
    let(:teacher_reference_number) { "1234567" }
    let(:matching_claims) { Claim.none }
    let(:hmrc_bank_validation_succeeded) { true }
    let(:claimant_first_name) { "Edna" }
    let(:claimant_surname) { "Krabappel" }
    let(:claimant_email_address) { "e.krabappel@springfield-elementary.edu" }

    let(:eligibility) do
      build(
        :further_education_payments_eligibility,
        teacher_reference_number: teacher_reference_number,
        verification: {
          verifier: {
            first_name: "Walter",
            last_name: "Skinner",
            email: "w.s.skinner@springfield-elementary.edu"
          }
        }
      )
    end

    let(:claim) do
      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        payroll_gender: payroll_gender,
        hmrc_bank_validation_succeeded: hmrc_bank_validation_succeeded,
        eligibility: eligibility,
        first_name: claimant_first_name,
        surname: claimant_surname,
        email_address: claimant_email_address
      )
    end

    let(:invariant_tasks) do
      [
        "identity_confirmation",
        "provider_verification",
        "student_loan_plan"
      ]
    end

    before do
      allow(Claim::MatchingAttributeFinder).to(
        receive(:new).and_return(double(matching_claims: matching_claims))
      )
    end

    context "when the claim has a teacher reference number" do
      it { is_expected.to include("employment") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the claim does not have a teacher reference number" do
      let(:teacher_reference_number) { nil }
      it { is_expected.not_to include("employment") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when there are matching claims" do
      let(:matching_claims) { Claim.all }
      it { is_expected.to include("matching_details") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when there are no matching claims" do
      it { is_expected.not_to include("matching_details") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the payroll_gender is missing" do
      let(:payroll_gender) { nil }
      it { is_expected.to include("payroll_gender") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the payroll_gender is present" do
      it { is_expected.not_to include("payroll_gender") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the bank details need validating" do
      let(:hmrc_bank_validation_succeeded) { false }
      it { is_expected.to include("payroll_details") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the bank details do not need validating" do
      it { is_expected.not_to include("payroll_details") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the claimant and provider names match" do
      let(:claimant_first_name) { "Walter" }
      let(:claimant_surname) { "Skinner" }
      it { is_expected.to include("provider_details") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the claimant and provider emails match" do
      let(:claimant_email_address) { "w.s.skinner@springfield-elementary.edu" }
      it { is_expected.to include("provider_details") }
      it { is_expected.to include(*invariant_tasks) }
    end

    context "when the claim and provider details are different" do
      it { is_expected.not_to include("provider_details") }
      it { is_expected.to include(*invariant_tasks) }
    end
  end
end
