require "rails_helper"

RSpec.feature "Admin checking a Student Loans claim" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

  scenario "service operator checks and approves a Student Loans claim" do
    claim = create(:claim, :submitted, policy: StudentLoans)

    visit admin_claims_path
    find("a[href='#{admin_claim_path(claim)}']").click
    click_on "View tasks"

    expect(page).to have_content("1. Qualifications")
    expect(page).to have_content("2. Employment")

    click_on "Check qualification information"
    expect(page).to have_content("Qualifications")
    expect(page).to have_content("Award year")
    expect(page).to have_content(claim.eligibility.qts_award_year_answer)

    click_on "Complete qualifications check and continue"

    expect(page).to have_content("Employment")
    expect(page).to have_content("Current school")
    expect(page).to have_link(claim.eligibility.current_school.name)

    click_on "Complete employment check and continue"

    expect(page).to have_content("Claim decision")

    choose "Approve"
    fill_in "Decision notes", with: "All checks passed!"
    click_on "Confirm decision"

    expect(page).to have_content("Claim has been approved successfully")
    expect(claim.decision).to be_approved
    expect(claim.decision.created_by).to eq(user)
  end
end
