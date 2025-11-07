require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::FraudRisk do
  describe "#perform" do
    context "with a claim that has flagged attributes" do
      it "creates a note" do
        claim = create(:claim, national_insurance_number: "AB123456C")

        create(
          :risk_indicator,
          field: "national_insurance_number",
          value: "AB123456C"
        )

        described_class.new(claim: claim).perform

        note = claim.notes.last

        expect(note.label).to eq("fraud_risk")

        expect(note.body).to eq(
          "This claim has been flagged as the national insurance number is " \
          "included on the fraud prevention list."
        )
      end
    end

    context "with a claim that has no flagged attributes" do
      it "doesn't create a note" do
        claim = create(:claim, national_insurance_number: "AB123456B")

        create(
          :risk_indicator,
          field: "national_insurance_number",
          value: "AB123456C"
        )

        expect { described_class.new(claim: claim).perform }.not_to(
          change { claim.notes.count }
        )
      end
    end
  end
end
