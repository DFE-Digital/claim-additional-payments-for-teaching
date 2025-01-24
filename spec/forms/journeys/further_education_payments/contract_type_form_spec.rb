require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::ContractTypeForm, type: :model do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }
  let(:answers) { build(:further_education_payments_answers, school_id: college.id) }
  let(:college) { create(:school) }
  let(:contract_type) { nil }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        contract_type:
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
          allow_value(nil)
          .for(:contract_type)
          .with_message("Select the type of contract you have with #{college.name}")
        )
      end
    end
  end

  describe "#save" do
    let(:contract_type) { %w[permanent fixed_term variable_hours].sample }

    it "updates the journey session" do
      expect { expect(subject.save).to be(true) }.to(
        change { journey_session.reload.answers.contract_type }
        .to(contract_type)
      )
    end

    context "when changing answers from fixed term contract" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: college.id,
          contract_type: "fixed_term",
          fixed_term_full_year: false,
          taught_at_least_one_term: true
        )
      end

      it "resets fixed_term_full_year + taught_at_least_one_term" do
        subject.contract_type = "permanent"

        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.contract_type }.to("permanent")
          .and(change { journey_session.answers.fixed_term_full_year }.to(nil)
          .and(change { journey_session.answers.taught_at_least_one_term }.to(nil)))
        )
      end
    end

    context "when changing answers from variable contract" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          school_id: college.id,
          contract_type: "variable_hours",
          taught_at_least_one_term: true
        )
      end

      it "resets taught_at_least_one_term" do
        subject.contract_type = "permanent"

        expect { expect(subject.save).to be(true) }.to(
          change { journey_session.reload.answers.contract_type }.to("permanent")
          .and(change { journey_session.answers.taught_at_least_one_term }.to(nil))
        )
      end
    end
  end

  describe "#clear_answers_from_session" do
    let(:answers) do
      build(
        :further_education_payments_answers,
        school_id: college.id,
        contract_type: "permanent"
      )
    end

    it "clears relevant answers from session" do
      expect {
        subject.clear_answers_from_session
      }.to change { journey_session.reload.answers.contract_type }.from("permanent").to(nil)
    end
  end
end
