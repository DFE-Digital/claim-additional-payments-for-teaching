require "rails_helper"

RSpec.feature "Admin approves a claim" do
  let(:user_id) { "userid-345" }

  context "User is logged in as a service operator" do
    before do
      sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user_id)
    end

    scenario "User can approve a claim" do
      freeze_time do
        submitted_claims = create_list(:claim, 5, :submitted)
        claim_to_approve = submitted_claims.first

        click_on "Check claims"

        expect(page).to have_content(claim_to_approve.reference)
        expect(page).to have_content("5 claims awaiting checking")

        find("a[href='#{admin_claim_path(claim_to_approve)}']").click
        perform_enqueued_jobs { click_on "Approve" }

        expect(claim_to_approve.check.checked_by).to eq(user_id)

        expect(page).to have_content("Claim has been approved successfully")
        expect(page).to_not have_content(claim_to_approve.reference)

        expect(ActionMailer::Base.deliveries.count).to eq(1)

        mail = ActionMailer::Base.deliveries.first

        expect(mail.subject).to match("been approved")
        expect(mail.to).to eq([claim_to_approve.email_address])
        expect(mail.body.raw_source).to match("been approved")
      end
    end

    context "When the payroll gender is missing" do
      let!(:claim_missing_payroll_gender) { create(:claim, :submitted, payroll_gender: :dont_know) }

      scenario "User is informed that the claim cannot be approved" do
        click_on "Check claims"
        find("a[href='#{admin_claim_path(claim_missing_payroll_gender)}']").click

        expect(page).to have_button("Approve", disabled: true)
        expect(page).to have_content("This claim cannot be approved, the payroll gender is missing")
      end
    end
  end

  context "User is logged in as a support user" do
    before do
      sign_in_to_admin_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
    end

    scenario "User cannot view claims to check" do
      expect(page).to_not have_link(nil, href: admin_claims_path)

      visit admin_claims_path

      expect(page.status_code).to eq(401)
      expect(page).to have_content("Not authorised")
    end
  end
end
