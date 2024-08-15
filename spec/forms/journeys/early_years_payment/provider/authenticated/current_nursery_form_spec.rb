require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::CurrentNurseryForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:nursery_urn) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        nursery_urn:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(nursery_urn)
        .for(:nursery_urn)
        .with_message("Select the nursery where your employee works")
      )
    end

    it do
      is_expected.not_to(
        allow_value("other")
        .for(:nursery_urn)
        .with_message("is not associated with your email address")
      )
    end
  end

  describe "#save" do
    let(:nursery_urn) { "none_of_the_above" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.nursery_urn }.to("none_of_the_above")
      )
    end
  end
end
