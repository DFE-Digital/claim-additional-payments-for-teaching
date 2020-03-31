require "rails_helper"

RSpec.describe "admin/notes controller" do
  let(:claim) { create(:claim, :submitted) }

  describe "admin/notes#index" do
    it "list the notes on a claim when the user is a service operator" do
      sign_in_as_service_operator
      note = create(:note, claim: claim, body: "Need to verify the student loan amount")
      user = note.created_by

      get admin_claim_notes_path(claim)

      expect(response.body).to include("Claim notes")
      expect(response.body).to include("Need to verify the student loan amount")
      expect(response.body).to include("by #{user.full_name}")
    end

    it "refuses requests from users without the service operator role" do
      non_service_operator_roles.each do |role|
        sign_in_to_admin_with_role(role)

        get admin_claim_notes_path(claim)

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("Not authorised")
      end
    end
  end

  describe "admin/notes#create" do
    before { @signed_in_user = sign_in_as_service_operator }

    it "creates a note against the claim when the user is a service operator" do
      post admin_claim_notes_path(claim), params: {note: {body: "Some note"}}

      expect(response).to redirect_to(admin_claim_notes_path(claim))

      expect(claim.notes.count).to eq 1

      note = claim.notes.last
      expect(note.body).to eq("Some note")
      expect(note.created_by).to eq(@signed_in_user)
    end

    it "shows an error message when the note is missing" do
      post admin_claim_notes_path(claim), params: {note: {body: ""}}

      expect(claim.notes.count).to eq(0)

      expect(response.body).to include("Enter a note")
    end

    it "refuses requests from users without the service operator role" do
      non_service_operator_roles.each do |role|
        sign_in_to_admin_with_role(role)

        post admin_claim_notes_path(claim), params: {note: {body: "Some note"}}

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("Not authorised")
      end
    end
  end
end
