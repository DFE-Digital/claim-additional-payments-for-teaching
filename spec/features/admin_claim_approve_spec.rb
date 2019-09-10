require "rails_helper"

RSpec.feature "Admin approves a claim" do
  context "User is logged in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, "12345")
      visit admin_path
      click_on "Sign in"
    end

    scenario "User can approve a claim" do
      freeze_time do
        submitted_claims = create_list(:claim, 5, :submitted)
        claim_to_approve = submitted_claims.first

        click_on "Approve claims"

        expect(page).to have_content(claim_to_approve.reference)

        find("a[href='#{admin_claim_path(claim_to_approve)}']").click
        click_on "Approve"

        claim_to_approve.reload

        expect(claim_to_approve.approved_at).to eq(Time.zone.now)
        expect(claim_to_approve.approved_by).to eq("12345")

        expect(page).to have_content("Claim has been approved successfully")
        expect(page).to_not have_content(claim_to_approve.reference)
      end
    end
  end

  context "User is logged in as a support user" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
      visit admin_path
      click_on "Sign in"
    end

    scenario "User cannot view claims to approve" do
      expect(page).to_not have_link(nil, href: admin_claims_path)

      visit admin_claims_path

      expect(page.status_code).to eq(401)
      expect(page).to have_content("Not authorised")
    end
  end
end
