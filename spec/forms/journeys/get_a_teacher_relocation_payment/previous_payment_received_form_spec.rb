require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::PreviousPaymentReceivedForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(claim: {previous_payment_received: option})
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    subject { form }
    let(:option) { nil }

    it do
      is_expected.not_to(
        allow_value(nil).for(:previous_payment_received).with_message(
          "Select Yes if you have previously received an international " \
          "relocation payment"
        )
      )
    end
  end

  describe "#save" do
    let(:option) { "Yes" }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change {
          journey_session.reload.answers.previous_payment_received
        }.to(true)
      )
    end
  end
end
