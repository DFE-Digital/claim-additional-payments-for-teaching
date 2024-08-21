require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::CheckYourAnswersForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:provider_contact_name) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        provider_contact_name:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(provider_contact_name)
        .for(:provider_contact_name)
        .with_message("You cannot submit this claim without providing your full name")
      )
    end
  end

  describe "#save" do
    let(:provider_contact_name) { "John Doe" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.provider_contact_name }.to("John Doe")
      )
    end
  end
end
