require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::EmailAddressForm do
  subject(:form) { described_class.new(journey:, journey_session:, params:) }

  let(:journey) { Journeys::EarlyYearsPayment::Provider }
  let(:journey_session) { build(:early_years_payment_provider_session) }
  # let(:params) { ActionController::Parameters.new({journey: "test-journey", slug: "test_slug", claim: claim_params}) }

  let(:params) do
    ActionController::Parameters.new(claim: {email_address: email_address})
  end

  let(:email_address) { "test@example.com" }

  it { should have_attributes(email_address: email_address) }

  describe "#save" do
    subject { form.save }

    it { should be_truthy }

    it "sets the email address" do
      subject
      expect(journey_session.reload.answers.email_address).to(
        eq(email_address)
      )
    end
  end
end
