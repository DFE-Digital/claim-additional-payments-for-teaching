require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TeachingResponsibilitiesForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        teaching_responsibilities:
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
    let(:teaching_responsibilities) { nil }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:teaching_responsibilities)
        .with_message("Tell us if you are a member of staff with teaching responsibilities")
      )
    end
  end

  describe "#save" do
    let(:teaching_responsibilities) { true }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.teaching_responsibilities }
        .to(true)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:teaching_responsibilities) { nil }

    let(:answers_hash) do
      {
        teaching_responsibilities: true
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.teaching_responsibilities }.from(true).to(nil)
    end
  end
end
