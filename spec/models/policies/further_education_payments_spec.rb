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
end
