require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ReturnerForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:returning_within_6_months) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        returning_within_6_months:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(returning_within_6_months)
        .for(:returning_within_6_months)
        .with_message("You must select an option below to continue")
      )
    end
  end

  describe "#save" do
    let(:returning_within_6_months) { "true" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.returning_within_6_months }.to(true)
      )
    end
  end
end
