require "rails_helper"

RSpec.feature "Admin approves a claim" do
  context "User is logged in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      visit admin_path
      click_on "Sign in"
    end

    scenario "User can approve a claim" do
      freeze_time do
        submitted_claims = create_list(:claim, 5, :submitted, submitted_at: DateTime.now, approved_at: nil)
        claim_to_approve = submitted_claims.first

        visit admin_claims_path

        expect(page).to have_content(claim_to_approve.reference)

        find("a[href='#{admin_claim_path(claim_to_approve)}']").click
        click_on "Approve"

        expect(claim_to_approve.reload.approved_at).to eq(DateTime.now)
        expect(page).to have_content("Claim has been approved successfully")
        expect(page).to_not have_content(claim_to_approve.reference)
      end
    end
  end
end
