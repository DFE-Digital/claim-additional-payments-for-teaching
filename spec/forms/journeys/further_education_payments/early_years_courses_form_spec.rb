require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::EarlyYearsCoursesForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:early_years_courses) { [""] }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        early_years_courses:
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
          .for(:early_years_courses)
          .with_message("Select the courses you teach")
        )
      end
    end

    context "when non-existent injection option selected" do
      it do
        is_expected.not_to(
          allow_value(["foo"])
          .for(:early_years_courses)
          .with_message("Select the courses you teach")
        )
      end
    end
  end

  describe "#save" do
    let(:early_years_courses) { ["eylevel2", "eylevel3"] }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.early_years_courses }.to(early_years_courses)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        early_years_courses: ["none"]
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.early_years_courses }.from(%w[none]).to([])
    end
  end
end
