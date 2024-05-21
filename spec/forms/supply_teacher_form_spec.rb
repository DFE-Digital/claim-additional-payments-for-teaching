require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::SupplyTeacherForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:journey_session) do
    build(:journeys_session, journey: journey::ROUTING_NAME)
  end

  let(:current_claim) do
    claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
    CurrentClaim.new(claims:)
  end

  let(:slug) { "supply-teacher" }

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

  describe "#employed_as_supply_teacher" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {}}) }

    context "when claim eligibility is missing employed_as_supply_teacher" do
      it "returns nil" do
        expect(form.employed_as_supply_teacher).to be_nil
      end
    end

    context "when claim eligibility has employed_as_supply_teacher" do
      let(:current_claim) do
        claims = journey::POLICIES.map do |policy|
          create(:claim, policy:, eligibility_attributes: {employed_as_supply_teacher: true})
        end
        CurrentClaim.new(claims:)
      end

      it "returns existing value for employed_as_supply_teacher" do
        expect(form.employed_as_supply_teacher).to be_truthy
      end
    end
  end

  describe "#save" do
    context "when a valid employed_as_supply_teacher is submitted" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_as_supply_teacher: "Yes"}}) }

      context "when claim eligibility is missing employed_as_supply_teacher" do
        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy:) }
          CurrentClaim.new(claims:)
        end

        it "saves employed_as_supply_teacher on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.employed_as_supply_teacher).to be_truthy
          end
        end
      end

      context "when claim eligibility has employed_as_supply_teacher" do
        let(:current_claim) do
          claims = journey::POLICIES.map do |policy|
            create(:claim, policy:, eligibility_attributes: {employed_as_supply_teacher: false})
          end
          CurrentClaim.new(claims:)
        end

        it "updates employed_as_supply_teacher on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.employed_as_supply_teacher).to be_truthy
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
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_as_supply_teacher: nil}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:employed_as_supply_teacher]).to eq ["Select yes if you are a supply teacher"]
      end
    end
  end
end
