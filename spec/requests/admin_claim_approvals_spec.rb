require "rails_helper"

RSpec.describe "Admin claim approvals", type: :request do
  context "when signed in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      post admin_dfe_sign_in_path
      follow_redirect!
    end

    describe "claim_approvals#create" do
      let(:claim) { create(:claim, :submitted) }

      it "approves a claim" do
        freeze_time do
          post admin_claim_approvals_path(claim_id: claim.id)

          claim.reload

          expect(claim.approved_at).to eq(Time.zone.now)
          expect(claim.approved_by).to eq("123")
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

    describe "claim_approvals#create" do
      let(:claim) { create(:claim, :submitted) }

      it "does not allow a claim to be approved" do
        post admin_claim_approvals_path(claim_id: claim.id)

        expect(response.code).to eq("401")
      end
    end
  end
end
