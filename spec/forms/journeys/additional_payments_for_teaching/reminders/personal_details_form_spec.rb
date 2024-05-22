require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::Reminders::PersonalDetailsForm, type: :model do
  subject(:form) { described_class.new(claim: form_data_object, journey:, journey_session:, params:) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { build(:additional_payments_session) }
  let(:form_data_object) { Reminder.new }
  let(:slug) { "personal-details" }
  let(:params) { ActionController::Parameters.new({slug:, form: form_params}) }
  let(:form_params) { {full_name: "John Doe"} }

  it { is_expected.to be_a(Form) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:full_name).with_message(form.i18n_errors_path(:"full_name.blank")) }
    it { is_expected.to validate_length_of(:full_name).is_at_most(100).with_message(form.i18n_errors_path(:"full_name.length")) }

    it { is_expected.to validate_presence_of(:email_address).with_message(form.i18n_errors_path(:"email_address.blank")) }
    it { is_expected.to validate_length_of(:email_address).is_at_most(256).with_message(form.i18n_errors_path(:"email_address.length")) }

    it { is_expected.to allow_value("valid@email.com").for(:email_address) }
    it { is_expected.not_to allow_value("in valid@email.com").for(:email_address) }
  end

  describe ".model_name" do
    it { expect(form.model_name).to eq(ActiveModel::Name.new(Form)) }
  end

  describe "#save" do
    subject(:save) { form.save }

    before do
      allow(form).to receive(:update!).and_return(true)
    end

    context "valid params" do
      let(:form_params) { {"full_name" => "John Doe", "email_address" => "john.doe@email.com"} }

      it "saves the attributes" do
        expect(save).to eq(true)
        expect(form).to have_received(:update!).with(form_params)
      end
    end

    context "invalid params" do
      let(:form_params) { {"full_name" => "John Doe", "email_address" => ""} }

      it "does not save the attributes" do
        expect(save).to eq(false)
        expect(form).not_to have_received(:update!)
      end
    end
  end
end
