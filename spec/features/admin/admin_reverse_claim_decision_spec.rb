require "rails_helper"

RSpec.feature "Admin reverses a claim decision" do
  it "allows admins to reverse a claim decision" do
    sign_in_as_service_operator

    claim = create(:claim, :submitted)

    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"

    choose "Reject"
    check "Ineligible subject"
    click_button "Confirm decision"

    visit new_admin_claim_amendment_path(claim)
    click_link "Undo decision"
    fill_in "Change notes", with: "test"
    click_button "Undo rejection"

    visit admin_claim_tasks_path(claim)
    click_on "Approve or reject this claim"

    choose "Approve"
    click_button "Confirm decision"

    expect(page).to have_content "Claim has been approved successfully"
  end
end
