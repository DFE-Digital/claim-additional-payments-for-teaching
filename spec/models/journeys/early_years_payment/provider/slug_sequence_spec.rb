require "rails_helper"

describe Journeys::EarlyYearsPayment::Provider::SlugSequence do
  let(:journey_session) { create(:early_years_payment_provider_session) }

  describe "#magic_link?" do
    subject { described_class.new(journey_session).magic_link?(slug) }

    context "when the current slug is not a magic link" do
      let(:slug) { "whatever" }

      it { is_expected.to be false }
    end

    context "when the current slug is not a magic link" do
      let(:slug) { "consent" }

      it { is_expected.to be true }
    end
  end
end
