require "rails_helper"

RSpec.describe StillTeachingForm do
  context "no school" do
    it "updates employment_status to no_school, no current_school set" do
      expected_claim_params = {
        eligibility_attributes: {
          current_school_id: nil,
          employment_status: "no_school"
        }
      }

      claim_params = {eligibility_attributes: {employment_status: "no_school"}}
      updated_claim_params = StillTeachingForm.extract_params(claim_params)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "somewhere else" do
    it "updates employment_status to different_school, no current_school set" do
      expected_claim_params = {
        eligibility_attributes: {
          current_school_id: nil,
          employment_status: "different_school"
        }
      }

      claim_params = {eligibility_attributes: {employment_status: "different_school"}}
      updated_claim_params = StillTeachingForm.extract_params(claim_params)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "suggested school is the claim_school (non-TID)" do
    it "updates employment_status to claim_school, current_school is set" do
      expected_claim_params = {
        eligibility_attributes: {
          current_school_id: "1",
          employment_status: "claim_school"
        }
      }

      claim_params = {eligibility_attributes: {current_school_id: "1", employment_status: "claim_school"}}
      updated_claim_params = StillTeachingForm.extract_params(claim_params)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end

  context "suggested school is suggest from TPS (TID journey)" do
    it "updates employment_status to TPS school, current_school is set" do
      expected_claim_params = {
        eligibility_attributes: {
          current_school_id: "2",
          employment_status: "recent_tps_school"
        }
      }

      claim_params = {eligibility_attributes: {current_school_id: "2", employment_status: "recent_tps_school"}}
      updated_claim_params = StillTeachingForm.extract_params(claim_params)

      expect(updated_claim_params).to eq(expected_claim_params)
    end
  end
end
