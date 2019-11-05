require "rails_helper"

RSpec.describe Claim::MatchingAttributeFinder do
  describe "#matching_claims" do
    let(:source_claim) {
      create(
        :claim,
        teacher_reference_number: "0902344",
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        building_society_roll_number: "123456789/ABCD",
      )
    }

    let!(:claim_with_no_matching_attributes) { create(:claim, :submitted) }
    let!(:unsubmitted_claim_with_matching_teacher_reference_number) { create(:claim, :submittable, teacher_reference_number: source_claim.teacher_reference_number) }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it "does not include the source claim, or claims that do not match, or claims that are not submitted" do
      expect(matching_claims).to be_empty
    end

    it "includes a claim with a matching teacher reference number" do
      claim_with_matching_attribute = create(:claim, :submitted, teacher_reference_number: source_claim.teacher_reference_number)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching national insurance number" do
      claim_with_matching_attribute = create(:claim, :submitted, national_insurance_number: source_claim.national_insurance_number)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching email address" do
      claim_with_matching_attribute = create(:claim, :submitted, email_address: source_claim.email_address)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching bank account number" do
      claim_with_matching_attribute = create(:claim, :submitted, bank_account_number: source_claim.bank_account_number)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching bank sort code" do
      claim_with_matching_attribute = create(:claim, :submitted, bank_sort_code: source_claim.bank_sort_code)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching building society roll number" do
      claim_with_matching_attribute = create(:claim, :submitted, building_society_roll_number: source_claim.building_society_roll_number)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "does not match claims with nil building society roll numbers" do
      source_claim.update!(building_society_roll_number: nil)
      create(:claim, :submitted, building_society_roll_number: nil)

      expect(matching_claims).to be_empty
    end

    it "does not match claims with blank building society roll numbers" do
      source_claim.update!(building_society_roll_number: "")
      create(:claim, :submitted, building_society_roll_number: "")

      expect(matching_claims).to be_empty
    end
  end
end
