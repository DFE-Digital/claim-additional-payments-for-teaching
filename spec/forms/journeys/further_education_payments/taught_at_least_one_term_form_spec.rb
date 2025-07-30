require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::TaughtAtLeastOneTermForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:school) { create(:school) }
  let(:answers_hash) do
    {school_id: school.id}
  end
  let(:taught_at_least_one_term) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        taught_at_least_one_term:
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
        .for(:taught_at_least_one_term)
        .with_message("Tell us if you have taught at #{school.name} for more than one academic term")
      )
    end
  end

  describe "#save" do
    let(:taught_at_least_one_term) { true }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.taught_at_least_one_term }.to(true)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        taught_at_least_one_term: true
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.taught_at_least_one_term }.from(true).to(nil)
    end
  end
end
