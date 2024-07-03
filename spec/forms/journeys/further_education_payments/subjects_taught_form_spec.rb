require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::SubjectsTaughtForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:subjects_taught) { [] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        subjects_taught:
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
    context "when no option selected" do
      let(:subjects_taught) { [] }

      it do
        is_expected.not_to(
          allow_value([])
          .for(:subjects_taught)
          .with_message("Select the subject areas you teach in or select you do not teach any of the listed subject areas")
        )
      end
    end

    context "when non-existent injection option selected" do
      let(:subjects_taught) { ["foo"] }

      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:subjects_taught)
          .with_message("Select the subject areas you teach in or select you do not teach any of the listed subject areas")
        )
      end
    end
  end

  describe "#save" do
    let(:subjects_taught) { ["chemistry", "maths"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.subjects_taught }.to(["chemistry", "maths"])
      )
    end
  end
end
