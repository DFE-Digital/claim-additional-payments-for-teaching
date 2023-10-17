require "rails_helper"

RSpec.describe CorrectSchoolFormChecker do
  context "change school" do
    it "updates school_somewhere_else to true and current_school_id to nil" do
      expected_claim_params = {
        eligibility_attributes: {
          school_somewhere_else: true,
          current_school_id: nil
        }
      }

      claim_params = {}
      CorrectSchoolFormChecker.call(claim_params, change_school: "true")

      expect(claim_params).to eq(expected_claim_params)
    end
  end

  context "somewhere else" do
    it "updates school_somewhere_else to true" do
      expected_claim_params = {
        eligibility_attributes: {
          school_somewhere_else: true
        }
      }

      claim_params = {eligibility_attributes: {current_school_id: "somewhere_else"}}
      CorrectSchoolFormChecker.call(claim_params, change_school: nil)

      expect(claim_params).to eq(expected_claim_params)
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
      CorrectSchoolFormChecker.call(claim_params, change_school: nil)

      expect(claim_params).to eq(expected_claim_params)
    end
  end
end
