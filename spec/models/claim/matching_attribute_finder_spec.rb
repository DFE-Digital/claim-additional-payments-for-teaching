require "rails_helper"

RSpec.describe Claim::MatchingAttributeFinder do
  describe "#matching_claims" do
    let(:source_claim) {
      create(:claim,
        teacher_reference_number: "0902344",
        national_insurance_number: "QQ891011C",
        email_address: "genghis.khan@mongol-empire.com",
        bank_account_number: "34682151",
        bank_sort_code: "972654",
        building_society_roll_number: "123456789/ABCD",
        policy: StudentLoans)
    }

    subject(:matching_claims) { Claim::MatchingAttributeFinder.new(source_claim).matching_claims }

    it "does not include the source claim" do
      expect(matching_claims).to be_empty
    end

    it "does not include claims that do not match" do
      create(:claim, :submitted)

      expect(matching_claims).to be_empty
    end

    it "does not include unsubmitted claims with matching attributes" do
      create(:claim, :submittable, teacher_reference_number: source_claim.teacher_reference_number)

      expect(matching_claims).to be_empty
    end

    it "does not include claims that match, but have a different policy" do
      create(:claim, :submitted, teacher_reference_number: source_claim.teacher_reference_number, policy: MathsAndPhysics)

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

    it "includes a claim with a matching national insurance number with a different capitalisation" do
      claim_with_matching_attribute = create(:claim, :submitted, national_insurance_number: source_claim.national_insurance_number.downcase)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching email address" do
      claim_with_matching_attribute = create(:claim, :submitted, email_address: source_claim.email_address)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "includes a claim with a matching email address with a different capitalisation" do
      claim_with_matching_attribute = create(:claim, :submitted, email_address: source_claim.email_address.upcase)

      expect(matching_claims).to eq([claim_with_matching_attribute])
    end

    it "does not include a claim with a matching bank account number" do
      create(:claim, :submitted, bank_account_number: source_claim.bank_account_number)

      expect(matching_claims).to eq([])
    end

    it "does not include a claim with a matching bank sort code" do
      create(:claim, :submitted, bank_sort_code: source_claim.bank_sort_code)

      expect(matching_claims).to eq([])
    end

    it "does not include a claim with a matching building society roll number" do
      create(:claim, :submitted, building_society_roll_number: source_claim.building_society_roll_number)

      expect(matching_claims).to eq([])
    end

    it "includes a claim with a matching bank account number and sort code" do
      source_claim.update!(building_society_roll_number: nil)
      claim_with_matching_attributes = create(:claim, :submitted,
        bank_account_number: source_claim.bank_account_number,
        bank_sort_code: source_claim.bank_sort_code)

      expect(matching_claims).to eq([claim_with_matching_attributes])
    end

    it "includes a claim with a matching bank account number, sort code and roll number" do
      claim_with_matching_attributes = create(:claim, :submitted,
        bank_account_number: source_claim.bank_account_number,
        bank_sort_code: source_claim.bank_sort_code,
        building_society_roll_number: source_claim.building_society_roll_number)

      expect(matching_claims).to eq([claim_with_matching_attributes])
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
