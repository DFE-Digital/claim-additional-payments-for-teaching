require "rails_helper"

RSpec.describe "admin/notes controller" do
  let(:claim) { create(:claim, :submitted) }

  describe "admin/notes#index" do
    before { @signed_in_user = sign_in_as_service_operator }

    it "list the notes on a claim" do
      note = create(:note, claim: claim, body: "Need to verify the student loan amount")
      user = note.created_by

      get admin_claim_notes_path(claim)

      expect(response.body).to include("Claim notes")
      expect(response.body).to include("Need to verify the student loan amount")
      expect(response.body).to include("by #{user.full_name}")
    end
  end

  describe "admin/notes#create" do
    before { @signed_in_user = sign_in_as_service_operator }

    it "creates a note against the claim by the signed-in user" do
      post admin_claim_notes_path(claim), params: {note: {body: "Some note"}}

      expect(response).to redirect_to(admin_claim_notes_path(claim))

      expect(claim.notes.count).to eq 1

      note = claim.notes.last
      expect(note.body).to eq("Some note")
      expect(note.created_by).to eq(@signed_in_user)
    end
  end
end
