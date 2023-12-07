require "rails_helper"

RSpec.describe SelectClaimSchoolForm do
  context "change school" do
    it "updates claim_school_somewhere_else to true and claim_school_id to nil" do
      expected_claim_params = {
        eligibility_attributes: {
          claim_school_somewhere_else: true,
          claim_school_id: nil
        }
      }

      claim_params = {}
      updated_claim_params = SelectClaimSchoolForm.extract_params(claim_params, change_school: "true")

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "somewhere else" do
    it "updates claim_school_somewhere_else to true" do
      expected_claim_params = {
        eligibility_attributes: {
          claim_school_id: nil,
          claim_school_somewhere_else: true
        }
      }

      claim_params = {eligibility_attributes: {claim_school_id: "somewhere_else"}}
      updated_claim_params = SelectClaimSchoolForm.extract_params(claim_params, change_school: nil)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "suggested school correct" do
    it "updates claim_school_somewhere_else to false" do
      expected_claim_params = {
        eligibility_attributes: {
          claim_school_id: "1",
          claim_school_somewhere_else: false
        }
      }

      claim_params = {eligibility_attributes: {claim_school_id: "1"}}
      updated_claim_params = SelectClaimSchoolForm.extract_params(claim_params, change_school: nil)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end
end
