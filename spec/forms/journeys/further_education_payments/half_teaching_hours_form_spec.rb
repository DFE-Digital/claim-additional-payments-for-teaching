require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::HalfTeachingHoursForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:half_teaching_hours) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        half_teaching_hours:
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
    let(:half_teaching_hours) { nil }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:half_teaching_hours)
        .with_message("Select yes if at least half your timetabled teaching hours are spent teaching 16-19-year-olds, including those up to 25 with an Education, Health and Care Plan")
      )
    end
  end

  describe "#save" do
    context "Yes" do
      let(:half_teaching_hours) { true }

      it "updates the journey session" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.half_teaching_hours }
          .to(true)
        )
      end
    end

    context "No" do
      let(:half_teaching_hours) { false }

      it "updates the journey session" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.half_teaching_hours }
          .to(false)
        )
      end
    end
  end

  describe "#clear_answers_from_session" do
    let(:journey_session) { create(:further_education_payments_session, answers:) }
    let(:answers) { build(:further_education_payments_answers, answers_hash) }

    let(:answers_hash) do
      {
        half_teaching_hours: true
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.half_teaching_hours }.from(true).to(nil)
    end
  end
end
