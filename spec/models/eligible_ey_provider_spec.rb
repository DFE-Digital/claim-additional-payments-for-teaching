require "rails_helper"

describe EligibleEyProvider do
  describe ".eligible_email?" do
    subject { described_class.eligible_email?(email) }

    let!(:eligible_ey_provider) { create(:eligible_ey_provider) }

    context "with a valid primary email address" do
      let(:email) { eligible_ey_provider.primary_key_contact_email_address }

      it { is_expected.to be true }
    end

    context "with a valid secondary email address" do
      let(:email) { eligible_ey_provider.secondary_contact_email_address }

      it { is_expected.to be true }
    end

    context "with an invalid address" do
      let(:email) { "some.other.email@example.com" }
      it { is_expected.to be false }
    end

    context "an empty email address"
  end
end
