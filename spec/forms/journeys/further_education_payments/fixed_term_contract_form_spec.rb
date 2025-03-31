require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::FixedTermContractForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, answers_hash) }
  let(:answers_hash) { {} }
  let(:fixed_term_full_year) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        fixed_term_full_year:
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
      travel_to Date.new(2024, 10, 1) do
        is_expected.not_to(
          allow_value(fixed_term_full_year)
          .for(:fixed_term_full_year)
          .with_message("Select yes if your fixed-term contract covers the full 2024 to 2025 academic year")
        )
      end
    end
  end

  describe "#save" do
    let(:fixed_term_full_year) { true }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.fixed_term_full_year }.to(true)
      )
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers_hash) do
      {
        fixed_term_full_year: true
      }
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.fixed_term_full_year }.from(true).to(nil)
    end
  end
end
