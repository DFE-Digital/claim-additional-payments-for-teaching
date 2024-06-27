require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::PassportNumberForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        passport_number: option
      }
    )
  end

  let(:option) { nil }

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    it do
      is_expected.to(
        validate_presence_of(:passport_number)
        .with_message("Enter your passport number")
      )
    end

    # Passport number contains non alphanumeric characters
    it do
      is_expected.not_to(
        allow_value("123456789012345$")
        .for(:passport_number)
        .with_message("Invalid passport number")
      )
    end

    # Passport number at max allowed length
    it do
      is_expected.to(
        allow_value("1234567890ABCDEfghij").for(:passport_number)
      )
    end

    # Passport number too long
    it do
      is_expected.not_to(
        allow_value("12345678901234567890A")
        .for(:passport_number)
        .with_message("Invalid passport number")
      )
    end
  end

  describe "#save" do
    let(:option) { "123456789012345" }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.passport_number }
        .to("123456789012345")
      )
    end
  end
end
