require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::VisaForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        visa_type: option
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
        validate_inclusion_of(:visa_type)
        .in_array(described_class::VISA_OPTIONS)
        .with_message("You must select the visa you currently have to live in England")
      )
    end
  end

  describe "#save" do
    let(:option) { "British National (Overseas) visa" }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.visa_type }
        .to("British National (Overseas) visa")
      )
    end
  end
end
