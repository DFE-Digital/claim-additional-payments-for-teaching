require "rails_helper"

RSpec.feature "Admin escalates a claim" do
  context "User is logged in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, "12345")
      visit admin_path
      click_on "Sign in"
    end

    scenario "User can escalate a claim" do
      freeze_time do
        submitted_claims = create_list(:claim, 5, :submitted)
        claim_to_escalate = submitted_claims.first

        click_on "Manage claims"

        expect(page).to have_content(claim_to_escalate.reference)

        find("a[href='#{admin_claim_path(claim_to_escalate)}']").click
        click_on "Escalate"

        fill_in "Escalation note", with: "Hmmm. Not sure about this"
        click_on "Escalate"

        claim_to_escalate.reload

        expect(claim_to_escalate.escalated_at).to eq(Time.zone.now)
        expect(claim_to_escalate.escalated_by).to eq("12345")

        escalation_note = claim_to_escalate.notes.last
        expect(escalation_note.body).to eq("Hmmm. Not sure about this")
        expect(escalation_note.created_by).to eq("12345")

        expect(page).to have_content("Claim has been escalated successfully")
      end
    end
  end
end
