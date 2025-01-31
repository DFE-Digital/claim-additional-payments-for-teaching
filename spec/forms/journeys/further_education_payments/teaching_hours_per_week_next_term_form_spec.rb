require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TeachingHoursPerWeekNextTermForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:college) { create(:school) }
  let(:answers_hash) do
    {school_id: college.id}
  end
  let(:teaching_hours_per_week_next_term) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        teaching_hours_per_week_next_term:
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
    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:teaching_hours_per_week_next_term)
        .with_message("Select yes if you are timetabled to teach at least 2.5 hours per week next term at #{college.name}")
      )
    end
  end

  describe "#save" do
    let(:teaching_hours_per_week_next_term) { "at_least_2_5" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.teaching_hours_per_week_next_term }.to(teaching_hours_per_week_next_term)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        teaching_hours_per_week_next_term: "at_least_2_5"
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.teaching_hours_per_week_next_term }.from("at_least_2_5").to(nil)
    end
  end
end
