require "rails_helper"

RSpec.feature "Rejecting a claim" do
  context "when the user is signed in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, "12345")
      visit admin_path
      click_on "Sign in"
    end

    scenario "they can reject a claim" do
      freeze_time do
        submitted_claims = create_list(:claim, 5, :submitted)
        claim_to_reject = submitted_claims.first

        click_on "Manage claims"

        expect(page).to have_content(claim_to_reject.reference)

        find("a[href='#{admin_claim_path(claim_to_reject)}']").click

        perform_enqueued_jobs { click_on "Reject" }

        expect(page).to have_content("Claim has been rejected successfully")

        claim_to_reject.reload

        expect(claim_to_reject.rejected_at).to eq(Time.zone.now)
        expect(claim_to_reject.rejected_by).to eq("12345")

        mail = ActionMailer::Base.deliveries.last

        expect(mail.subject).to eq(
          "Your claim to get your student loan repayments back has been rejected, reference number: #{claim_to_reject.reference}"
        )
        expect(mail.body.raw_source).to match(
          "Unfortunately your claim to get your student loan payments back has been denied."
        )
      end
    end
  end
end
