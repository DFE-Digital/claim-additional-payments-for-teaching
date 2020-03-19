require "rails_helper"

RSpec.feature "Admin checking a claim without a verified identity" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "the service operator is told the identity hasn't been confirmed and can approve the claim" do
    claim_without_identity_confirmation = create(:claim, :unverified)

    click_on "View claims"
    find("a[href='#{admin_claim_tasks_path(claim_without_identity_confirmation)}']").click
    click_on "View full claim"

    expect(page).to have_content("The claimant did not complete GOV.UK Verify")
    expect(page).to have_content(claim_without_identity_confirmation.school.phone_number)

    choose "Approve"
    fill_in "Decision notes", with: "Identity confirmed via phone call"
    click_on "Confirm decision"

    expect(claim_without_identity_confirmation.latest_decision.created_by).to eq(user)
    expect(claim_without_identity_confirmation.latest_decision.notes).to eq("Identity confirmed via phone call")
  end
end
