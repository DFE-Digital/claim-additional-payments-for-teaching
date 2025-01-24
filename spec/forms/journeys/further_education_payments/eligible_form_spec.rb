require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::EligibleForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }

  let(:params) do
    ActionController::Parameters.new
  end

  let(:school) { create(:school, :further_education) }

  let(:answers) { build(:further_education_payments_answers, teaching_hours_per_week: "more_than_12", school_id: school.id) }

  subject do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#save" do
    let!(:eligible_fe_provider) { create(:eligible_fe_provider, ukprn: school.ukprn, max_award_amount: 4_000.0) }

    it "updates award_amount" do
      expect { subject.save }.to(
        change { journey_session.reload.answers.award_amount }
        .to(4_000.0)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers) do
      build(
        :further_education_payments_answers,
        teaching_hours_per_week: "more_than_12",
        school_id: school.id,
        award_amount: 6_000
      )
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.award_amount }.from(6_000).to(nil)
    end
  end
end
