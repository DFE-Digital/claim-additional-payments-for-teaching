require "rails_helper"

RSpec.describe "Admin claim rejections", type: :request do
  context "when signed in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      post admin_dfe_sign_in_path
      follow_redirect!
    end

    describe "claim_rejections#new" do
      it "renders the rejection form for a checkable claim" do
        claim = create(:claim, :submitted)
        get new_admin_claim_rejection_path(claim_id: claim.id)
        expect(response.body).to include("Reject claim #{claim.reference}")
      end

      it "redirects if the claim has already been checked" do
        claim = create(:claim, :approved)
        get new_admin_claim_rejection_path(claim_id: claim.id)
        expect(response).to redirect_to(admin_claim_path(claim))
        follow_redirect!
        expect(response.body).to include("Claim already checked")
      end
    end

    describe "claim_rejections#create" do
      let(:claim) { create(:claim, :submitted) }

      it "rejects a claim" do
        freeze_time do
          post admin_claim_rejections_path(claim_id: claim.id, note: {body: "some reason."})
          follow_redirect!

          expect(response.body).to include("Claim has been rejected successfully")

          claim.reload
          expect(claim.rejected_at).to eq(Time.zone.now)
          expect(claim.rejected_by).to eq("123")
          note = claim.notes.last
          expect(note.body).to eq("some reason.")
          expect(note.created_by).to eq("123")
        end
      end

      it "does not reject a claim when the note is missing" do
        post admin_claim_rejections_path(claim_id: claim.id, note: {body: ""})

        expect(response.body).to include("Enter a rejection note")

        claim.reload
        expect(claim.rejected_at).to be_nil
        expect(claim.rejected_by).to be_nil
      end

      context "when the claim has been checked already" do
        let(:claim) { create(:claim, :approved) }

        it "redirects users back to the claim" do
          post admin_claim_rejections_path(claim_id: claim.id, note: {body: "Bogus."})
          expect(response).to redirect_to(admin_claim_path(claim))
          follow_redirect!
          expect(response.body).to include("Claim already checked")
        end
      end
    end
  end
end
