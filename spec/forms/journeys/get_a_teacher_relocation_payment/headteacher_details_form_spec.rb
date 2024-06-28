require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::HeadteacherDetailsForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) { ActionController::Parameters.new(claim: {}) }

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
        validate_presence_of(:school_headteacher_name)
        .with_message("Enter the headteacher's name")
      )
    end
  end

  describe "#save" do
    let(:params) do
      ActionController::Parameters.new(claim: {
        school_headteacher_name: "Seymour Skinner"
      })
    end

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.school_headteacher_name }
        .to("Seymour Skinner")
      )
    end
  end
end
