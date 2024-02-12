require "rails_helper"

RSpec.describe CorrectSchoolForm do
  context "change school" do
    it "updates school_somewhere_else to true and current_school_id to nil" do
      expected_claim_params = {
        eligibility_attributes: {
          school_somewhere_else: true,
          current_school_id: nil
        }
      }

      claim_params = {}
      updated_claim_params = CorrectSchoolForm.extract_params(claim_params, change_school: "true")

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "somewhere else" do
    it "updates school_somewhere_else to true" do
      expected_claim_params = {
        eligibility_attributes: {
          current_school_id: nil,
          school_somewhere_else: true
        }
      }

      claim_params = {eligibility_attributes: {current_school_id: "somewhere_else"}}
      updated_claim_params = CorrectSchoolForm.extract_params(claim_params, change_school: nil)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "suggested school correct" do
    it "updates school_somewhere_else to false" do
      expected_claim_params = {
        eligibility_attributes: {
          current_school_id: "1",
          school_somewhere_else: false
        }
      }

      claim_params = {eligibility_attributes: {current_school_id: "1"}}
      updated_claim_params = CorrectSchoolForm.extract_params(claim_params, change_school: nil)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end
end
