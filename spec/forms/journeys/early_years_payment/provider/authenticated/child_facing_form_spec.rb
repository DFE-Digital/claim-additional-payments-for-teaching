require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::ChildFacingForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:child_facing_confirmation_given) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        child_facing_confirmation_given:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it do
      is_expected.not_to(
        allow_value(child_facing_confirmation_given)
        .for(:child_facing_confirmation_given)
        .with_message("You must select an option below to continue")
      )
    end
  end

  describe "#save" do
    let(:child_facing_confirmation_given) { true }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.child_facing_confirmation_given }.to(true)
      )
    end
  end
end
