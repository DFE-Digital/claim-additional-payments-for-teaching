require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EntireTermContractForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:current_claim) do
    claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
    CurrentClaim.new(claims:)
  end

  let(:slug) { "entire-term-contract" }

  subject(:form) { described_class.new(claim: current_claim, journey:, params:) }

  context "unpermitted claim param" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {random_param: 1}}) }

    it "raises an error" do
      expect { form }.to raise_error ActionController::UnpermittedParameters
    end
  end

  describe "#has_entire_term_contract" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {}}) }

    context "when claim eligibility is missing has_entire_term_contract" do
      it "returns nil" do
        expect(form.has_entire_term_contract).to be_nil
      end
    end

    context "when claim eligibility has has_entire_term_contract" do
      let(:current_claim) do
        claims = journey::POLICIES.map do |policy|
          create(:claim, policy:, eligibility_attributes: {has_entire_term_contract: true})
        end
        CurrentClaim.new(claims:)
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
        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
          CurrentClaim.new(claims:)
        end

        it "saves has_entire_term_contract on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.has_entire_term_contract).to be_truthy
          end
        end
      end

      context "when claim eligibility has has_entire_term_contract" do
        let(:current_claim) do
          claims = journey::POLICIES.map do |policy|
            create(:claim, policy:, eligibility_attributes: {has_entire_term_contract: false})
          end
          CurrentClaim.new(claims:)
        end

        it "updates has_entire_term_contract on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.has_entire_term_contract).to be_truthy
          end
        end
      end

      context "when claim model fails validation unexpectedly" do
        it "raises an error" do
          allow(current_claim).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

          expect { form.save }.to raise_error(ActiveRecord::RecordInvalid)
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
