require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::QualificationForm, type: :model do
  before { create(:journey_configuration, :additional_payments) }

  let(:additional_payments_journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }

  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  describe "validations" do
    subject(:form) do
      described_class.new(
        journey: additional_payments_journey,
        claim: current_claim,
        params: ActionController::Parameters.new
      )
    end

    it do
      is_expected.to(
        validate_inclusion_of(:qualification)
        .in_array(described_class::QUALIFICATION_OPTIONS)
        .with_message("Select the route you took into teaching")
      )
    end
  end

  describe "#save" do
    let(:form) do
      described_class.new(
        journey: additional_payments_journey,
        claim: current_claim,
        params: params
      )
    end

    context "when invalid" do
      let(:params) do
        ActionController::Parameters.new(claim: {qualification: "invalid"})
      end

      it "returns false" do
        expect { expect(form.save).to be false }.not_to(
          change { claim.eligibility.reload.qualification }
        )
      end
    end

    context "when valid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {qualification: "postgraduate_itt"}
        )
      end

      it "updates the claim's eligibility" do
        expect { expect(form.save).to be true }.to(
          change { claim.eligibility.reload.qualification }
          .from(nil).to("postgraduate_itt")
        )
      end

      it "resets depended answers" do
        claim.eligibility.update!(eligible_itt_subject: "mathematics")

        expect { expect(form.save).to be true }.to(
          change { claim.eligibility.reload.eligible_itt_subject }
          .from("mathematics").to(nil)
        )
      end
    end
  end

  describe "#backlink_path" do
    let(:form) do
      described_class.new(
        journey: additional_payments_journey,
        claim: current_claim,
        params: ActionController::Parameters.new(
          {
            journey: "additional-payments",
            slug: "qualification"
          }
        )
      )
    end

    it "returns the previous page in the journey" do
      expect(form.backlink_path).to eq("/additional-payments/poor-performance")
    end
  end
end
