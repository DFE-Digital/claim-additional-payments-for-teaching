require "rails_helper"

RSpec.describe "Undoing decisions", type: :request do
  context "when signed in as a service operator" do
    before { @signed_in_user = sign_in_as_service_operator }

    describe "#create" do
      let(:claim) { create(:claim, :approved) }
      let(:decision) { claim.latest_decision }

      it "sets a decision to undone and creates an amendment record" do
        post admin_claim_decision_undos_path(claim_id: claim.id, decision_id: decision.id), params: {
          amendment: {
            notes: "Here are some notes"
          }
        }

        expect(response).to redirect_to(admin_claim_tasks_path(claim))

        expect(decision.reload.undone?).to eq(true)
        expect(claim.amendments.count).to eq(1)

        amendment = claim.amendments.first

        expect(amendment.claim).to eq(claim)
        expect(amendment.notes).to eq("Here are some notes")
        expect(amendment.claim_changes).to eq({decision: ["approved", "undecided"]})
        expect(amendment.created_by).to eq(@signed_in_user)
      end

      it "does not save the decision or admendment if the claim has been subsequently paid" do
        create(:payment, claims: [claim])

        post admin_claim_decision_undos_path(claim_id: claim.id, decision_id: decision.id), params: {
          amendment: {
            notes: "Here are some notes"
          }
        }

        expect(response.body).to include("This claim cannot have its decision undone")

        expect(decision.reload.undone?).to eq(false)
        expect(claim.amendments.count).to eq(0)
      end

      it "does not save the decision or amendment if the amendment is invalid" do
        post admin_claim_decision_undos_path(claim_id: claim.id, decision_id: decision.id), params: {
          amendment: {
            notes: ""
          }
        }

        expect(response.body).to include("Enter a message to explain why you are making this amendment")

        expect(decision.reload.undone?).to eq(false)
        expect(claim.amendments.count).to eq(0)
      end
    end
  end
end
