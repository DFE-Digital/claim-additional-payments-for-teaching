require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::Reminders::EmailVerificationForm do
  subject(:form) do
    described_class.new(reminder: reminder, journey:, journey_session:, params:)
  end

  let(:secret) { ROTP::Base32.random }
  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:answers) do
    {email_verification_secret: secret}
  end
  let(:journey_session) { build(:additional_payments_session, answers:) }
  let(:reminder) { Reminder.create! }
  let(:slug) { "email-verification" }
  let(:params) { ActionController::Parameters.new({slug:, form: form_params}) }
  let(:form_params) { {one_time_password: "123456"} }

  describe ".model_name" do
    it { expect(form.model_name).to eq(ActiveModel::Name.new(Form)) }
  end

  describe "#save" do
    subject(:save) { form.save }

    context "valid params" do
      let(:form_params) do
        {
          "one_time_password" => OneTimePassword::Generator.new(secret:).code,
          "sent_one_time_password_at" => Time.now
        }
      end

      it "saves the attributes" do
        expect(save).to eq(true)
        expect(reminder.reload.email_verified).to be true
      end
    end

    context "invalid params" do
      let(:form_params) do
        {
          "one_time_password" => OneTimePassword::Generator.new(secret:).code,
          "sent_one_time_password_at" => ""
        }
      end

      it "does not save the attributes" do
        expect { expect(save).to eq(false) }.not_to(
          change { reminder.reload.email_verified }
        )
      end
    end
  end
end
