require "rails_helper"

RSpec.describe "Admin claim checks", type: :request do
  context "when signed in as a service operator" do
    before do
      sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    end

    describe "claim_checks#create" do
      let(:claim) { create(:claim, :submitted) }

      it "can approve a claim" do
        post admin_claim_checks_path(claim_id: claim.id, check: {result: "approved"})

        follow_redirect!

        expect(response.body).to include("Claim has been approved successfully")

        expect(claim.check.checked_by).to eq("123")
        expect(claim.check.result).to eq("approved")
      end

      it "can reject a claim" do
        post admin_claim_checks_path(claim_id: claim.id, check: {result: "rejected"})

        follow_redirect!

        expect(response.body).to include("Claim has been rejected successfully")

        expect(claim.check.checked_by).to eq("123")
        expect(claim.check.result).to eq("rejected")
      end

      context "when claim is already checked" do
        let(:claim) { create(:claim, :approved) }

        it "shows an error" do
          post admin_claim_checks_path(claim_id: claim.id, check: {result: "approved"})

          follow_redirect!

          expect(response.body).to include("Claim already checked")
        end
      end

      context "when the claim is missing a payroll gender" do
        let(:claim) { create(:claim, :submitted, payroll_gender: :dont_know) }
        before do
          post admin_claim_checks_path(claim_id: claim.id, check: {result: result})
          follow_redirect!
        end

        context "and the user attempts to approve" do
          let(:result) { "approved" }
          it "shows an error" do
            expect(response.body).to include("Claim cannot be approved")
          end
        end

        context "and the user attempts to reject" do
          let(:result) { "rejected" }
          it "doesn’t show an error and rejects successfully" do
            expect(response.body).not_to include("Claim cannot be approved")
            expect(response.body).to include("Claim has been rejected successfully")
          end
        end
      end
    end
  end

  context "when signed in as a support user" do
    before do
      sign_in_to_admin_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
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
