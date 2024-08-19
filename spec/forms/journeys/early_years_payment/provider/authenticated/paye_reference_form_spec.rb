require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::PayeReferenceForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:paye_reference) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        paye_reference:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it { should validate_presence_of(:paye_reference).with_message("Enter a valid PAYE reference") }
    it { should allow_value("123/A").for(:paye_reference) }
    it { should allow_value("123/ABC123DEF4").for(:paye_reference) }
    it { should_not allow_value("ABC/123").for(:paye_reference).with_message("Enter a valid PAYE reference") }
    it { should_not allow_value("123/").for(:paye_reference).with_message("Enter a valid PAYE reference") }
    it { should_not allow_value("123/1234567890A").for(:paye_reference).with_message("Enter a valid PAYE reference") }
    it { should_not allow_value("ABC/123$").for(:paye_reference).with_message("Enter a valid PAYE reference") }
  end

  describe "#save" do
    let(:paye_reference) { "123/ABC" }

    it "updates the journey session" do
      expect { subject.save }.to(
        change { journey_session.answers.paye_reference }.to(paye_reference)
      )
    end
  end
end
