require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::ChemistryCoursesForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:chemistry_courses) { [""] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        chemistry_courses:
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
      it do
        is_expected.not_to(
          allow_value([""])
          .for(:chemistry_courses)
          .with_message("Select the courses you teach")
        )
      end
    end

    context "when non-existent injection option selected" do
      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:chemistry_courses)
          .with_message("Select the courses you teach")
        )
      end
    end
  end

  describe "#save" do
    let(:chemistry_courses) { ["alevel_chemistry", "gcse_chemistry"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.chemistry_courses }.to(chemistry_courses)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        chemistry_courses: ["none"]
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.chemistry_courses }.from(%w[none]).to([])
    end
  end
end
