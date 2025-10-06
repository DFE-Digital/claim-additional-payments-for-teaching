require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::HoursTeachingEligibleSubjectsForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session) }
  let(:hours_teaching_eligible_subjects) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        hours_teaching_eligible_subjects:
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
    let(:hours_teaching_eligible_subjects) { nil }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:hours_teaching_eligible_subjects)
        .with_message("Select yes if you spend at least half of your timetabled teaching hours teaching these courses")
      )
    end
  end

  describe "#save" do
    context "Yes" do
      let(:hours_teaching_eligible_subjects) { true }

      it "updates the journey session" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.hours_teaching_eligible_subjects }
          .to(true)
        )
      end
    end

    context "No" do
      let(:hours_teaching_eligible_subjects) { false }

      it "updates the journey session" do
        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.hours_teaching_eligible_subjects }
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
        hours_teaching_eligible_subjects: true
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.hours_teaching_eligible_subjects }.from(true).to(nil)
    end
  end
end
