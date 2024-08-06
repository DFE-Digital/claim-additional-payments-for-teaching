require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::EmailAddressForm do
  subject(:form) { described_class.new(journey:, journey_session:, params:) }

  let(:journey) { Journeys::EarlyYearsPayment::Provider }
  let(:journey_session) { build(:early_years_payment_provider_session) }

  let(:params) do
    ActionController::Parameters.new(claim: {email_address: email_address})
  end

  let(:email_address) { "test@example.com" }

  it { should have_attributes(email_address: email_address) }

  context "when the email address is eligible" do
    before { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

    describe "#save" do
      subject { form.save }

      around do |example|
        travel_to DateTime.new(2024, 1, 1, 12, 0, 0) do
          example.run
        end
      end

      before do
        allow(OneTimePassword::Generator).to receive(:new).and_return(
          instance_double(OneTimePassword::Generator, code: "111111")
        )
      end

      let(:policy) { journey_session.answers.policy }
      let(:claim_subject) { I18n.t("#{policy.locale_key}.claim_subject") }

      it { should be_truthy }

      it "sets the email address" do
        subject
        expect(journey_session.reload.answers.email_address).to(
          eq(email_address)
        )
      end

      it "sends an email" do
        subject

        expect(email_address).to have_received_email(
          "e0b78a08-601b-40ba-a97f-61fb00a7c951",
          magic_link: "https://www.example.com/early-years-payment-provider/consent?code=111111"
        )
      end

      it "updates sent_one_time_password_at" do
        subject
        expect(journey_session.answers.sent_one_time_password_at).to(
          eq(DateTime.new(2024, 1, 1, 12, 0, 0))
        )
      end

      it "resets email_verified" do
        subject
        expect(journey_session.answers.email_verified).to be_nil
      end

      context "when the email address has been previously verified, and a new one is submitted" do
        before do
          journey_session.answers.assign_attributes(email_address: "new@example.com", email_verified: true)
          journey_session.save!
        end

        it "resets email_verified" do
          subject
          expect(journey_session.answers.email_verified).to be_nil
        end
      end

      context "when the email address submitted has been previously verified, and is the same" do
        before do
          journey_session.answers.assign_attributes(email_address: email_address, email_verified: true)
          journey_session.save!
        end

        it "returns email_verified" do
          subject
          expect(journey_session.answers.email_verified).to be true
        end
      end
    end
  end
end
