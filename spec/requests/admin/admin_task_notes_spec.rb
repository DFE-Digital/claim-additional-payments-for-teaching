require "rails_helper"

RSpec.describe "admin/notes controller for task notes" do
  let(:claim) { create(:claim, :submitted) }
  let(:task_name) { "employment" }

  describe "admin/notes#create for task notes" do
    before { @signed_in_user = sign_in_as_service_operator }

    it "creates a note against the claim with the task label" do
      post admin_claim_task_notes_path(claim, task_name), params: {note: {body: "Some task note"}}

      expect(response).to redirect_to(admin_claim_task_path(claim, name: task_name))

      expect(claim.notes.count).to eq 1

      note = claim.notes.last
      expect(note.body).to eq("Some task note")
      expect(note.created_by).to eq(@signed_in_user)
      expect(note.label).to eq(task_name)
    end

    it "redirects with flash alert when note body is blank" do
      post admin_claim_task_notes_path(claim, task_name), params: {note: {body: ""}}

      expect(response).to redirect_to(admin_claim_task_path(claim, name: task_name))
      expect(flash[:alert]).to eq("Enter a note")
      expect(claim.notes.count).to eq 0
    end

    it "refuses requests from users without the service operator role" do
      sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)

      post admin_claim_task_notes_path(claim, task_name), params: {note: {body: "Some note"}}

      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to include("Not authorised")
    end
  end
end
