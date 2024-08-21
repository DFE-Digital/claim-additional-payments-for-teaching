require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::EmployeeEmailForm, type: :model do
  let(:journey) { Journeys::EarlyYearsPayment::Provider::Authenticated }
  let(:journey_session) { create(:early_years_payment_provider_authenticated_session) }
  let(:practitioner_email_address) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        practitioner_email_address:
      }
    )
  end

  subject do
    described_class.new(journey_session:, journey:, params:)
  end

  describe "validations" do
    it { should validate_presence_of(:practitioner_email_address).with_message("Enter a valid email address") }
  end

  describe "#save" do
    let(:practitioner_email_address) { "practitioner@example.com" }

    it "updates the journey session" do
      expect { subject.save }.to(
        change { journey_session.answers.practitioner_email_address }.to(practitioner_email_address)
      )
    end
  end
end
