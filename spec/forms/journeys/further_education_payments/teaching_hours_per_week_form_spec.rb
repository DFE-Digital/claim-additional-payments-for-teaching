require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TeachingHoursPerWeekForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:college) { create(:school) }
  let(:answers_hash) do
    {school_id: college.id}
  end
  let(:teaching_hours_per_week) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        teaching_hours_per_week:
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
    let(:teaching_hours_per_week) { nil }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:teaching_hours_per_week)
        .with_message("Select how many hours per week you are timetabled to teach during the current term")
      )
    end
  end

  describe "#save" do
    let(:teaching_hours_per_week) { "more-than-12" }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.teaching_hours_per_week }.to(teaching_hours_per_week)
      )
    end
  end
end
