require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::NationalityForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        nationality: option
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
        validate_inclusion_of(:nationality)
        .in_array(NATIONALITIES)
        .with_message("Choose your nationality")
      )
    end
  end

  describe "#save" do
    let(:option) { "Australian" }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.nationality }
        .to("Australian")
      )
    end
  end
end
