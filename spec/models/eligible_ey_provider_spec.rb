require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments::EligibleEyProvider do
  describe ".eligible_email?" do
    subject { described_class.eligible_email?(email) }

    let!(:eligible_ey_provider) { create(:eligible_ey_provider, :with_secondary_contact_email_address) }

    context "with a valid primary email address" do
      let(:email) { eligible_ey_provider.primary_key_contact_email_address }

      it { is_expected.to be true }
    end

    context "with a valid primary email address but with different capitalisation" do
      let!(:eligible_ey_provider) { create(:eligible_ey_provider, primary_key_contact_email_address: "test@example.com") }
      let(:email) { "TeSt@EXAMPLE.com" }

      it { is_expected.to be true }
    end

    context "with a valid secondary email address" do
      let(:email) { eligible_ey_provider.secondary_contact_email_address }

      it { is_expected.to be true }
    end

    context "with a valid secondary email address but with different capitalisation" do
      let!(:eligible_ey_provider) { create(:eligible_ey_provider, secondary_contact_email_address: "secondary@example.com") }
      let(:email) { "SeCoNdArY@EXAMPLE.com" }

      it { is_expected.to be true }
    end

    context "with an invalid address" do
      let(:email) { "some.other.email@example.com" }
      it { is_expected.to be_falsey }
    end

    context "an empty email address" do
      let(:email) { "" }
      it { is_expected.to be_falsey }
    end

    context "a nil email address" do
      let(:email) { nil }
      it { is_expected.to be_falsey }
    end

    context "when there are EligibleEyProviders with no secondary_contact_email_address" do
      let!(:eligible_ey_provider) { create(:eligible_ey_provider, secondary_contact_email_address: nil) }

      context "with a valid primary email address" do
        let(:email) { eligible_ey_provider.primary_key_contact_email_address }

        it { is_expected.to be true }
      end

      context "with an invalid address" do
        let(:email) { "some.other.email@example.com" }
        it { is_expected.to be_falsey }
      end

      context "an empty email address" do
        let(:email) { "" }
        it { is_expected.to be_falsey }
      end

      context "a nil email address" do
        let(:email) { nil }
        it { is_expected.to be_falsey }
      end
    end
  end
end
