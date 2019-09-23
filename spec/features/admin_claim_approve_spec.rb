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
        expect(page).to have_content("5 claims awaiting approval")

        find("a[href='#{admin_claim_path(claim_to_approve)}']").click
        perform_enqueued_jobs { click_on "Approve" }

        expect(claim_to_approve.check.checked_by).to eq("12345")

        expect(page).to have_content("Claim has been approved successfully")
        expect(page).to_not have_content(claim_to_approve.reference)

        expect(ActionMailer::Base.deliveries.count).to eq(1)

        mail = ActionMailer::Base.deliveries.first

        expect(mail.subject).to eq(
          "Your claim to get your student loan repayments back has been approved, reference number: #{claim_to_approve.reference}"
        )
        expect(mail.body.raw_source).to match(
          "Your claim to get your student loan repayments back has been approved"
        )
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
