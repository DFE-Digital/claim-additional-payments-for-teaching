require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments do
  describe "#payroll_file_name" do
    it "returns correct name" do
      expect(subject.payroll_file_name).to eql("FELUPEXPANSION")
    end
  end

  describe ".rejected_reasons" do
    before do
      FeatureFlag.create!(
        name: "fe_provider_identity_verification",
        enabled: true
      )
    end

    subject { described_class.rejected_reasons(claim) }

    describe "alternative_identity_verification_check_failed" do
      context "when the claim requires alternative identity verification" do
        let(:claim) do
          create(
            :claim,
            :submitted,
            policy: described_class,
            onelogin_idv_at: 1.day.ago,
            identity_confirmed_with_onelogin: false
          )
        end

        it do
          is_expected.to include(
            :alternative_identity_verification_check_failed
          )
        end
      end

      context "when the claim does not require alternative identity verification" do
        let(:claim) do
          create(
            :claim,
            :submitted,
            policy: described_class,
            onelogin_idv_at: 1.day.ago,
            identity_confirmed_with_onelogin: true
          )
        end

        it do
          is_expected.not_to include(
            :alternative_identity_verification_check_failed
          )
        end
      end
    end
  end

  describe "#decision_deadline_date" do
    let(:claim) do
      build(
        :claim,
        :further_education,
        :submitted,
        submitted_at: Date.new(2025, 9, 2)
      )
    end

    it "is 25 weeks after claim has been submitted" do
      expect(subject.decision_deadline_date(claim)).to eql(Date.new(2026, 2, 24))
    end
  end

  describe "#provider_verification_completed!" do
    let(:claim) { create(:claim) }

    it "invokes Tasks::FeProviderVerificationV2Job" do
      expect(Tasks::FeProviderVerificationV2Job).to receive(:perform_later)

      subject.provider_verification_completed!(claim)
    end
  end
end
