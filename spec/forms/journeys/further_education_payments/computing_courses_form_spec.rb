require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::ComputingCoursesForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:computing_courses) { [""] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        computing_courses:
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
          .for(:computing_courses)
          .with_message("Select the courses that you teach, or select ‘I do not teach any of these courses’")
        )
      end
    end

    context "when non-existent injection option selected" do
      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:computing_courses)
          .with_message("Select the courses that you teach, or select ‘I do not teach any of these courses’")
        )
      end
    end
  end

  describe "#save" do
    let(:computing_courses) { ["digitalskills_quals", "tlevel_digitalsupport"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.computing_courses }.to(computing_courses)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        computing_courses: ["none"]
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.computing_courses }.from(%w[none]).to([])
    end
  end
end
