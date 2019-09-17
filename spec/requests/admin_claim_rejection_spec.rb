require "rails_helper"

RSpec.describe "Admin claim rejections", type: :request do
  context "when signed in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      post admin_dfe_sign_in_path
      follow_redirect!
    end

    describe "claim_rejections#create" do
      let(:claim) { create(:claim, :submitted) }

      it "rejects a claim" do
        freeze_time do
          post admin_claim_rejections_path(claim_id: claim.id)

          follow_redirect!

          expect(response.body).to include("Claim has been rejected successfully")

          claim.reload

          expect(claim.rejected_at).to eq(Time.zone.now)
          expect(claim.rejected_by).to eq("123")
        end
      end

      context "when the claim is already approved" do
        let(:claim) { create(:claim, :approved) }

        it "cannot be rejected when already approved" do
          post admin_claim_rejections_path(claim_id: claim.id)

          follow_redirect!

          expect(response.body).to include("Claim cannot be rejected")

          claim.reload
        end
      end
    end
  end
end
