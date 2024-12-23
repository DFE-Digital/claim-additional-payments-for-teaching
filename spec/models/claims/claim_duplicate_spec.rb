require "rails_helper"

RSpec.describe Claims::ClaimDuplicate, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:matching_attributes) }

    describe "uniquness" do
      it "doesn't allow a duplicate to be registered more than once" do
        original_claim = create(:claim, created_at: 1.day.ago)
        duplicate_claim = create(:claim, created_at: Time.zone.now)

        described_class.create!(
          original_claim: original_claim,
          duplicate_claim: duplicate_claim,
          matching_attributes: ["email_address"]
        )

        claim_duplicate = described_class.new(
          original_claim: original_claim,
          duplicate_claim: duplicate_claim,
          matching_attributes: ["email_address"]
        )

        expect(claim_duplicate).not_to be_valid
        expect(claim_duplicate.errors[:duplicate_claim]).to include(
          "has already been registered as a duplicate"
        )
      end
    end

    describe "original_claim_is_older" do
      it "is valid when the original claim is older" do
        original_claim = create(:claim, created_at: 1.day.ago)
        duplicate_claim = create(:claim, created_at: Time.zone.now)

        claim_duplicate = described_class.new(
          original_claim: original_claim,
          duplicate_claim: duplicate_claim,
          matching_attributes: ["email_address"]
        )

        expect(claim_duplicate).to be_valid
      end

      it "is invalid when the original claim is newer" do
        original_claim = create(:claim, created_at: Time.zone.now)
        duplicate_claim = create(:claim, created_at: 1.day.ago)

        claim_duplicate = described_class.new(
          original_claim: original_claim,
          duplicate_claim: duplicate_claim,
          matching_attributes: ["email_address"]
        )

        expect(claim_duplicate).not_to be_valid
        expect(claim_duplicate.errors[:original_claim]).to include(
          "must be older than the duplicate claim"
        )
      end
    end

    describe "claims_are_not_the_same" do
      it "is valid when the claims are different" do
        original_claim = create(:claim)
        duplicate_claim = create(:claim)

        claim_duplicate = described_class.new(
          original_claim: original_claim,
          duplicate_claim: duplicate_claim,
          matching_attributes: ["email_address"]
        )

        expect(claim_duplicate).to be_valid
      end

      it "is invalid when the claims are the same" do
        claim = create(:claim)

        claim_duplicate = described_class.new(
          original_claim: claim,
          duplicate_claim: claim,
          matching_attributes: ["email_address"]
        )

        expect(claim_duplicate).not_to be_valid
        expect(claim_duplicate.errors[:duplicate_claim]).to include(
          "can't be the same as the original claim"
        )
      end
    end
  end
end
