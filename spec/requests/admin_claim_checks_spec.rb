require "rails_helper"

RSpec.describe "Admin claim approvals", type: :request do
  context "when signed in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      post admin_dfe_sign_in_path
      follow_redirect!
    end

    describe "claim_checks#create" do
      let(:claim) { create(:claim, :submitted) }

      it "approves a claim" do
        freeze_time do
          post admin_claim_checks_path(claim_id: claim.id, result: "approved")

          follow_redirect!

          expect(response.body).to include("Claim has been approved successfully")

          expect(claim.check.checked_by).to eq("123")
          expect(claim.check.result).to eq("approved")
        end
      end

      context "when claim is already approved" do
        let(:claim) { create(:claim, :approved) }

        it "shows an error" do
          post admin_claim_checks_path(claim_id: claim.id, result: "approved")

          follow_redirect!

          expect(response.body).to include("Claim already checked")
        end
      end
    end
  end

  context "when signed in as a support user" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
      post admin_dfe_sign_in_path
      follow_redirect!
    end

    describe "claim_checks#create" do
      let(:claim) { create(:claim, :submitted) }

      it "does not allow a claim to be approved" do
        post admin_claim_checks_path(claim_id: claim.id, result: "approved")

        expect(response.code).to eq("401")
      end
    end
  end
end
