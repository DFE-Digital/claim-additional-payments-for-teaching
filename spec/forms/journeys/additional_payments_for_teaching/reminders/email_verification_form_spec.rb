require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::Reminders::EmailVerificationForm do
  subject(:form) { described_class.new(claim: form_data_object, journey:, journey_session:, params:) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { build(:additional_payments_session) }
  let(:form_data_object) { Reminder.new }
  let(:slug) { "email-verification" }
  let(:params) { ActionController::Parameters.new({slug:, form: form_params}) }
  let(:form_params) { {one_time_password: "123456"} }

  it { is_expected.to be_a(EmailVerificationForm) }

  describe ".model_name" do
    it { expect(form.model_name).to eq(ActiveModel::Name.new(Form)) }
  end

  describe "#save" do
    subject(:save) { form.save }

    before do
      allow(form).to receive(:update!).and_return(true)
    end

    context "valid params" do
      let(:form_params) { {"one_time_password" => OneTimePassword::Generator.new.code, "sent_one_time_password_at" => Time.now} }

      it "saves the attributes" do
        expect(save).to eq(true)
        expect(form).to have_received(:update!).with(email_verified: true)
      end
    end

    context "invalid params" do
      let(:form_params) { {"one_time_password" => OneTimePassword::Generator.new.code, "sent_one_time_password_at" => ""} }

      it "does not save the attributes" do
        expect(save).to eq(false)
        expect(form).not_to have_received(:update!)
      end
    end
  end
end
