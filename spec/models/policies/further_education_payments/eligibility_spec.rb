require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::Eligibility do
  describe "#provider_verification_status" do
    let(:eligibility) { build(:further_education_payments_eligibility) }
    let(:claim_verification_overdue) { false }

    before do
      allow(Policies::FurtherEducationPayments).to receive(:verification_overdue?).and_return(claim_verification_overdue)
    end

    context "when provider verification has not started" do
      it "returns 'not_started'" do
        eligibility.provider_verification_started_at = nil
        eligibility.provider_verification_completed_at = nil
        expect(eligibility.provider_verification_status).to eq(Policies::FurtherEducationPayments::ProviderVerificationConstants::STATUS_NOT_STARTED)
      end
    end

    context "when provider verification is in progress" do
      it "returns 'in_progress'" do
        eligibility.provider_verification_started_at = Time.current
        eligibility.provider_verification_completed_at = nil
        expect(eligibility.provider_verification_status).to eq(Policies::FurtherEducationPayments::ProviderVerificationConstants::STATUS_IN_PROGRESS)
      end
    end

    context "when provider verification is completed" do
      it "returns 'completed'" do
        eligibility.provider_verification_started_at = 1.hour.ago
        eligibility.provider_verification_completed_at = Time.current
        expect(eligibility.provider_verification_status).to eq(Policies::FurtherEducationPayments::ProviderVerificationConstants::STATUS_COMPLETED)
      end
    end

    context "when provider verification is overdue" do
      let(:claim_verification_overdue) { true }

      it "returns 'overdue'" do
        eligibility.provider_verification_started_at = nil
        eligibility.provider_verification_completed_at = nil
        expect(eligibility.provider_verification_status).to eq(Policies::FurtherEducationPayments::ProviderVerificationConstants::STATUS_OVERDUE)
      end
    end
  end

  describe "#provider_verification_started?" do
    let(:eligibility) { build(:further_education_payments_eligibility) }

    it "returns false when provider_verification_started_at is nil" do
      eligibility.provider_verification_started_at = nil
      expect(eligibility.provider_verification_started?).to be false
    end

    it "returns true when provider_verification_started_at is present" do
      eligibility.provider_verification_started_at = Time.current
      expect(eligibility.provider_verification_started?).to be true
    end
  end

  describe "#processed_by_label" do
    let(:eligibility) { build(:further_education_payments_eligibility) }
    let(:user) { build(:dfe_signin_user, given_name: "John", family_name: "Smith") }

    context "when no provider is assigned" do
      it "returns 'Not processed'" do
        eligibility.provider_assigned_to = nil
        expect(eligibility.processed_by_label).to eq(Policies::FurtherEducationPayments::ProviderVerificationConstants::PROCESSED_BY_NOT_PROCESSED)
      end
    end

    context "when a provider is assigned" do
      it "returns the provider's full name" do
        eligibility.provider_assigned_to = user
        expect(eligibility.processed_by_label).to eq("John Smith")
      end
    end
  end

  describe "#awaiting_provider_verification?" do
    subject { claim.eligibility.awaiting_provider_verification? }

    let(:claim) do
      create(
        :claim,
        :further_education,
        :eligible,
        eligibility:,
        academic_year: AcademicYear.new(2025)
      )
    end

    let(:eligibility) do
      build(
        :further_education_payments_eligibility,
        repeat_applicant_check_passed:
      )
    end

    context "when not verified" do
      context "when repeat_applicant_check_passed=true" do
        let(:repeat_applicant_check_passed) { true }

        it { is_expected.to be true }
      end

      context "when repeat_applicant_check_passed=false" do
        let(:repeat_applicant_check_passed) { false }

        it { is_expected.to be false }
      end

      context "when repeat_applicant_check_passed=nil" do
        let(:repeat_applicant_check_passed) { nil }

        it { is_expected.to be false }
      end
    end
  end
end
