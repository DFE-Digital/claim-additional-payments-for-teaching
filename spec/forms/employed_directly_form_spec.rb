require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EmployedDirectlyForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:journey_session) do
    build(:journeys_session, journey: journey::ROUTING_NAME)
  end

  let(:current_claim) do
    claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
    CurrentClaim.new(claims:)
  end

  let(:slug) { "employed-directly" }

  subject(:form) do
    described_class.new(
      claim: current_claim,
      journey_session:,
      journey:,
      params:
    )
  end

  context "unpermitted claim param" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {random_param: 1}}) }

    it "raises an error" do
      expect { form }.to raise_error ActionController::UnpermittedParameters
    end
  end

  describe "#employed_directly" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {}}) }

    context "when claim eligibility is missing employed_directly" do
      it "returns nil" do
        expect(form.employed_directly).to be_nil
      end
    end

    context "when claim eligibility has employed_directly" do
      let(:current_claim) do
        claims = journey::POLICIES.map do |policy|
          create(:claim, policy:, eligibility_attributes: {employed_directly: true})
        end
        CurrentClaim.new(claims:)
      end

      it "returns existing value for employed_directly" do
        expect(form.employed_directly).to be_truthy
      end
    end
  end

  describe "#save" do
    context "when a valid employed_directly is submitted" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_directly: "Yes"}}) }

      context "when claim eligibility is missing employed_directly" do
        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
          CurrentClaim.new(claims:)
        end

        it "saves employed_directly on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.employed_directly).to be_truthy
          end
        end
      end

      context "when claim eligibility has employed_directly" do
        let(:current_claim) do
          claims = journey::POLICIES.map do |policy|
            create(:claim, policy:, eligibility_attributes: {employed_directly: false})
          end
          CurrentClaim.new(claims:)
        end

        it "updates employed_directly on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.employed_directly).to be_truthy
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

    context "when employed_directly is not provided" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_directly: nil}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:employed_directly]).to eq ["Select yes if you are directly employed by your school"]
      end
    end
  end
end
