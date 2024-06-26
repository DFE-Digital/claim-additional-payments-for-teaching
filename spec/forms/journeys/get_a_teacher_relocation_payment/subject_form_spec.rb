require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::SubjectForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        subject: option
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
        validate_inclusion_of(:subject)
        .in_array(%w[physics combined_with_physics languages other])
        .with_message("Choose a subject")
      )
    end
  end

  describe "#available_options" do
    subject { form.available_options }

    context "when a teacher" do
      before { journey_session.answers.application_route = "teacher" }

      it do
        is_expected.to(
          match_array(%w[physics combined_with_physics languages other])
        )
      end
    end

    context "when a trainee" do
      before { journey_session.answers.application_route = "salaried_trainee" }

      it { is_expected.to(match_array(%w[physics languages other])) }
    end
  end

  describe "#save" do
    let(:option) { "physics" }

    it "updates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.subject }
        .to("physics")
      )
    end
  end
end
