require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::DuplicateClaimsCheck do
  describe "#perform" do
    context "when the claim has duplicates" do
      it "marks the claim as having duplicates" do
        existing_claim = create(
          :claim,
          :submitted,
          email_address: "test@example.com",
          first_name: "one"
        )

        _other_duplicate_claim = create(
          :claim,
          :submitted,
          email_address: "test@example.com",
          first_name: "two"
        )

        new_claim = create(
          :claim,
          :submitted,
          email_address: "test@example.com",
          first_name: "three"
        )

        expect { described_class.new(claim: new_claim).perform }.to(
          change(Claims::ClaimDuplicate, :count).by(1)
        )

        expect(existing_claim.reload.duplicates).to include(new_claim)
        expect(new_claim.reload.originals).to include(existing_claim)

        claim_duplicate = new_claim.claim_duplicates_as_duplicate_claim.last

        expect(claim_duplicate.original_claim).to eq(existing_claim)
        expect(claim_duplicate.duplicate_claim).to eq(new_claim)
        expect(claim_duplicate.matching_attributes).to eq(["email_address"])
      end

      it "is idempotent" do
        existing_claim = create(
          :claim,
          :submitted,
          email_address: "test@example.com",
          first_name: "one"
        )

        new_claim = create(
          :claim,
          :submitted,
          email_address: "test@example.com",
          first_name: "two"
        )

        Claims::ClaimDuplicate.create!(
          original_claim: existing_claim,
          duplicate_claim: new_claim,
          matching_attributes: ["email_address"]
        )

        expect { described_class.new(claim: new_claim).perform }.not_to(
          change(existing_claim.duplicates, :count)
        )
      end
    end

    context "when the claim has no duplicates" do
      it "does not mark the claim as having duplicates" do
        existing_claim = create(
          :claim,
          :submitted,
          email_address: "test1@example.com",
          first_name: "one"
        )

        new_claim = create(
          :claim,
          :submitted,
          email_address: "test2@example.com",
          first_name: "two"
        )

        described_class.new(claim: new_claim).perform

        expect(existing_claim.reload.duplicates).not_to include(new_claim)
      end
    end
  end
end
