require "rails_helper"

RSpec.describe Claim::MatchingAttributeFinder do
  describe "#claim_ids_with_matching_attributes" do
    let(:teacher_reference_number) { "0902344" }
    let(:national_insurance_number) { "QQ891011C" }
    let(:email_address) { "genghis.khan@mongol-empire.com" }
    let(:bank_account_number) { "34682151" }
    let(:bank_sort_code) { "972654" }
    let(:building_society_roll_number) { "123456789/ABCD" }

    let(:source_claim) {
      create(
        :claim,
        teacher_reference_number: teacher_reference_number,
        national_insurance_number: national_insurance_number,
        email_address: email_address,
        bank_account_number: bank_account_number,
        bank_sort_code: bank_sort_code,
        building_society_roll_number: building_society_roll_number,
      )
    }

    let!(:another_claim) { create(:claim, :submitted) }

    let(:claim_with_matching_attributes) { build(:claim, :submitted) }

    let(:claims_with_matching_attributes) { Claim::MatchingAttributeFinder.new(source_claim).claim_ids_with_matching_attributes }

    it "does not include the id of the source claim" do
      expect(claims_with_matching_attributes).not_to include(source_claim.id)
    end

    it "does not include the id of a claim without any matcheing attributes" do
      expect(claims_with_matching_attributes).not_to include(another_claim.id)
    end

    it "includes the id of a claim with a mathching teacher reference number" do
      claim_with_matching_attributes.teacher_reference_number = teacher_reference_number
      claim_with_matching_attributes.save

      expect(claims_with_matching_attributes).to include(claim_with_matching_attributes.id)
      expect(claims_with_matching_attributes[claim_with_matching_attributes.id]).to include("Teacher reference number")
    end

    it "includes the id of a claim with a mathching national insurance number" do
      claim_with_matching_attributes.national_insurance_number = national_insurance_number
      claim_with_matching_attributes.save

      expect(claims_with_matching_attributes).to include(claim_with_matching_attributes.id)
      expect(claims_with_matching_attributes[claim_with_matching_attributes.id]).to include("National insurance number")
    end

    it "includes the id of a claim with a mathching email address" do
      claim_with_matching_attributes.email_address = email_address
      claim_with_matching_attributes.save

      expect(claims_with_matching_attributes).to include(claim_with_matching_attributes.id)
      expect(claims_with_matching_attributes[claim_with_matching_attributes.id]).to include("Email address")
    end

    it "includes the id of a claim with a mathching bank account number" do
      claim_with_matching_attributes.bank_account_number = bank_account_number
      claim_with_matching_attributes.save

      expect(claims_with_matching_attributes).to include(claim_with_matching_attributes.id)
      expect(claims_with_matching_attributes[claim_with_matching_attributes.id]).to include("Bank account number")
    end

    it "includes the id of a claim with a mathching bank sort code" do
      claim_with_matching_attributes.bank_sort_code = bank_sort_code
      claim_with_matching_attributes.save

      expect(claims_with_matching_attributes).to include(claim_with_matching_attributes.id)
      expect(claims_with_matching_attributes[claim_with_matching_attributes.id]).to include("Bank sort code")
    end

    it "includes the id of a claim with a mathching building society roll number" do
      claim_with_matching_attributes.building_society_roll_number = building_society_roll_number
      claim_with_matching_attributes.save

      expect(claims_with_matching_attributes).to include(claim_with_matching_attributes.id)
      expect(claims_with_matching_attributes[claim_with_matching_attributes.id]).to include("Building society roll number")
    end
  end
end
