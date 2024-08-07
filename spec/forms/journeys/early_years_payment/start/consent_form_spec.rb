require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::ConsentForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider }
  let(:journey_session) { create(:early_years_payment_provider_session) }
  let(:consent_given) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        consent_given:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(consent_given)
        .for(:consent_given)
        .with_message("You must be able to confirm this information to continue")
      )
    end
  end

  describe "#save" do
    let(:consent_given) { true }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.consent_given }.to(true)
      )
    end
  end
end
