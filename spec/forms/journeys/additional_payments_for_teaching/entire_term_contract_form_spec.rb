require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EntireTermContractForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:journey_session) { build(:additional_payments_session) }

  let(:slug) { "entire-term-contract" }

  subject(:form) do
    described_class.new(
      journey:,
      journey_session:,
      params:
    )
  end

  describe "#has_entire_term_contract" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {}}) }

    context "when claim eligibility is missing has_entire_term_contract" do
      it "returns nil" do
        expect(form.has_entire_term_contract).to be_nil
      end
    end

    context "when claim eligibility has has_entire_term_contract" do
      before do
        journey_session.answers.assign_attributes(
          has_entire_term_contract: true
        )
        journey_session.save!
      end

      it "returns existing value for has_entire_term_contract" do
        expect(form.has_entire_term_contract).to be_truthy
      end
    end
  end

  describe "#save" do
    context "when a valid has_entire_term_contract is submitted" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {has_entire_term_contract: "Yes"}}) }

      context "when claim eligibility is missing has_entire_term_contract" do
        it "saves has_entire_term_contract on claim eligibility" do
          expect(form.save).to be true

          expect(journey_session.answers.has_entire_term_contract).to eq true
        end
      end

      context "when claim eligibility has has_entire_term_contract" do
        before do
          journey_session.answers.assign_attributes(
            has_entire_term_contract: false
          )

          journey_session.save!
        end

        it "updates has_entire_term_contract on claim eligibility" do
          expect(form.save).to be true

          expect(journey_session.answers.has_entire_term_contract).to eq true
        end
      end
    end

    context "when employed_as_supply_teacher is not provided" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {has_entire_term_contract: nil}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:has_entire_term_contract]).to eq ["Select yes if you have a contract to teach at the same school for an entire term or longer"]
      end
    end
  end
end
