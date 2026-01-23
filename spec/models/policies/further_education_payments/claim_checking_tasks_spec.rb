require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::ClaimCheckingTasks, feature_flag: :fe_provider_identity_verification do
  describe "#applicable_task_names" do
    subject { described_class.new(claim) }

    let(:payroll_gender) { "male" }
    let(:teacher_reference_number) { "1234567" }
    let(:hmrc_bank_validation_succeeded) { true }
    let(:claimant_first_name) { "Edna" }
    let(:claimant_surname) { "Krabappel" }
    let(:claimant_email_address) { "e.krabappel@springfield-elementary.edu" }
    let(:onelogin_idv_at) { 1.day.ago }
    let(:identity_confirmed_with_onelogin) { true }
    let(:academic_year) { AcademicYear.current }

    let(:eligibility) do
      build(
        :further_education_payments_eligibility,
        :provider_verification_completed,
        teacher_reference_number: teacher_reference_number,
        verified_by: create(
          :dfe_signin_user,
          given_name: "Walter",
          family_name: "Skinner",
          email: "w.s.skinner@springfield-elementary.edu"
        )
      )
    end

    let(:claim) do
      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        academic_year: academic_year,
        payroll_gender: payroll_gender,
        hmrc_bank_validation_succeeded: hmrc_bank_validation_succeeded,
        eligibility: eligibility,
        first_name: claimant_first_name,
        surname: claimant_surname,
        email_address: claimant_email_address,
        onelogin_idv_at: onelogin_idv_at,
        identity_confirmed_with_onelogin: identity_confirmed_with_onelogin
      )
    end

    let(:duplicate_claim) do
      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        email_address: claimant_email_address,
        academic_year: academic_year,
        eligibility: eligibility
      )
    end

    let(:invariant_tasks) do
      [
        "one_login_identity",
        "fe_provider_verification_v2",
        "student_loan_plan"
      ]
    end

    context "when a year 1 fe claim" do
      let(:academic_year) { AcademicYear.new(2024) }
      it { expect(subject.applicable_task_names).to include("provider_verification") }
      it { expect(subject.applicable_task_names).not_to include("fe_provider_verification_v2") }
    end

    context "when not a year 1 fe claim" do
      it { expect(subject.applicable_task_names).not_to include("provider_verification") }
    end

    context "when the claim has a teacher reference number" do
      it { expect(subject.applicable_task_names).to include("employment") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the claim does not have a teacher reference number" do
      let(:teacher_reference_number) { nil }
      it { expect(subject.applicable_task_names).not_to include("employment") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when there are matching claims" do
      before { duplicate_claim }
      it { expect(subject.applicable_task_names).to include("matching_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when there are no matching claims" do
      it { expect(subject.applicable_task_names).not_to include("matching_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the payroll_gender is missing" do
      let(:payroll_gender) { nil }
      it { expect(subject.applicable_task_names).to include("payroll_gender") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the payroll_gender is present" do
      it { expect(subject.applicable_task_names).not_to include("payroll_gender") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the bank details need validating" do
      let(:hmrc_bank_validation_succeeded) { false }
      it { expect(subject.applicable_task_names).to include("payroll_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the bank details do not need validating" do
      it { expect(subject.applicable_task_names).not_to include("payroll_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the claimant and provider names match" do
      let(:claimant_first_name) { "Walter" }
      let(:claimant_surname) { "Skinner" }
      it { expect(subject.applicable_task_names).to include("provider_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the claimant and provider emails match" do
      let(:claimant_email_address) { "w.s.skinner@springfield-elementary.edu" }
      it { expect(subject.applicable_task_names).to include("provider_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the claim and provider details are different" do
      it { expect(subject.applicable_task_names).not_to include("provider_details") }
      it { expect(subject.applicable_task_names).to include(*invariant_tasks) }
    end

    context "when the claimant fails IDV" do
      let(:identity_confirmed_with_onelogin) { false }
      it { expect(subject.applicable_task_names).to include("fe_alternative_verification") }
    end

    context "when Y1 claim and failed OL idv" do
      let(:claim) do
        create(
          :claim,
          :further_education,
          :with_failed_ol_idv,
          academic_year: AcademicYear.new("2024/2025")
        )
      end

      it "shows alternative_identity_verification task" do
        expect(subject.applicable_task_names).to include("alternative_identity_verification")
      end
    end

    context "when not Y1 claim and failed OL idv" do
      let(:claim) do
        create(
          :claim,
          :further_education,
          :with_failed_ol_idv,
          academic_year: AcademicYear.new("2025/2026")
        )
      end

      it "does not show alternative_identity_verification task" do
        expect(subject.applicable_task_names).not_to include("alternative_identity_verification")
      end

      it "shows alternative_verification task" do
        expect(subject.applicable_task_names).to include("fe_alternative_verification")
      end
    end
  end
end
