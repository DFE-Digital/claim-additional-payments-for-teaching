require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::PoorPerformanceForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:subject_to_formal_performance_action) { nil }
  let(:subject_to_disciplinary_action) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        subject_to_formal_performance_action:,
        subject_to_disciplinary_action:
      }
    )
  end

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "validations" do
    context "when no options selected" do
      it do
        is_expected.not_to(
          allow_value(nil)
          .for(:subject_to_formal_performance_action)
          .with_message("Select yes if you are subject to formal action for poor performance at work")
        )
      end

      it do
        is_expected.not_to(
          allow_value(nil)
          .for(:subject_to_disciplinary_action)
          .with_message("Select yes if you are subject to disciplinary action")
        )
      end
    end
  end

  describe "#save" do
    let(:subject_to_formal_performance_action) { "true" }
    let(:subject_to_disciplinary_action) { "false" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.subject_to_formal_performance_action }.to(true)
        .and(change { journey_session.reload.answers.subject_to_disciplinary_action }.to(false))
      )
    end
  end
end
