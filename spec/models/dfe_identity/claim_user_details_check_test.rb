require "rails_helper"

RSpec.describe DfeIdentity::ClaimUserDetailsCheck do
  let(:claim) { instance_double("Claim") }
  let(:result) { "true" }
  let(:valid_teacher_id_user_info) {
    {
      "given_name" => "John",
      "family_name" => "Doe",
      "trn" => "123456",
      "birthdate" => "1990-01-01",
      "ni_number" => "AB123456C",
      "trn_match_ni_number" => "True"
    }
  }

  before do
    allow(claim).to receive(:teacher_id_user_info).and_return(valid_teacher_id_user_info)
  end

  describe ".call" do
    it "calls #save_details_check_result on a new instance of ClaimUserDetailsCheck" do
      expect_any_instance_of(DfeIdentity::ClaimUserDetailsCheck).to receive(:save_details_check_result)

      DfeIdentity::ClaimUserDetailsCheck.call(claim, result)
    end
  end

  describe "#save_details_check_result" do
    before do
      allow(claim).to receive(:update)
    end

    context "when the result is 'true'" do
      it "updates the claim's details_check attribute to 'true'" do
        expect(claim).to receive(:update).with(details_check: "true")

        DfeIdentity::ClaimUserDetailsCheck.new(claim, "true").save_details_check_result
      end

      it "calls ClaimUserDetailsUpdater.call with the claim" do
        expect(DfeIdentity::ClaimUserDetailsUpdater).to receive(:call).with(claim)

        DfeIdentity::ClaimUserDetailsCheck.new(claim, "true").save_details_check_result
      end
    end

    context "when the result is 'false'" do
      it "updates the claim's details_check attribute to 'false'" do
        expect(claim).to receive(:update).with(details_check: "false")

        DfeIdentity::ClaimUserDetailsCheck.new(claim, "false").save_details_check_result
      end

      it "calls ClaimUserDetailsReset.call with the claim" do
        expect(DfeIdentity::ClaimUserDetailsReset).to receive(:call).with(claim)

        DfeIdentity::ClaimUserDetailsCheck.new(claim, "false").save_details_check_result
      end
    end

    context "when the result is not 'true' or 'false'" do
      it "does not update the claim's details_check attribute" do
        expect(claim).not_to receive(:update)

        DfeIdentity::ClaimUserDetailsCheck.new(claim, "invalid").save_details_check_result
      end

      it "does not call ClaimUserDetailsUpdater.call or ClaimUserDetailsReset.call" do
        expect(DfeIdentity::ClaimUserDetailsUpdater).not_to receive(:call)
        expect(DfeIdentity::ClaimUserDetailsReset).not_to receive(:call)

        DfeIdentity::ClaimUserDetailsCheck.new(claim, "invalid").save_details_check_result
      end
    end
  end
end
