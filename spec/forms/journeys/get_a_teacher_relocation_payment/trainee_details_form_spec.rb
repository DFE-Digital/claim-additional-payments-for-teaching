require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::TraineeDetailsForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        state_funded_secondary_school: option
      }
    )
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
        allow_value(nil)
        .for(:state_funded_secondary_school)
        .with_message("Select the option that applies to you")
      )
    end
  end

  describe "#save" do
    let(:option) { true }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.state_funded_secondary_school }
        .to(true)
      )
    end
  end
end
