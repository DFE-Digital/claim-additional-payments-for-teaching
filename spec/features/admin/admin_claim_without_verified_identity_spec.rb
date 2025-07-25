require "rails_helper"

RSpec.feature "Admin checking a claim without a verified identity" do
  before do
    create(:journey_configuration, :student_loans)
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "the service operator can do a manual identity check and approve the claim" do
    unverified_claim = create(:claim, :unverified)

    click_on "Claims"
    find("a[href='#{admin_claim_tasks_path(unverified_claim)}']").click

    expect(page).to have_content("1. Identity confirmation")

    click_on I18n.t("admin.tasks.identity_confirmation.title")

    expect(page).to have_content("Did #{unverified_claim.full_name} submit the claim?")
    expect(page).not_to have_content("The claimant’s identity matches DQT records.")
    expect(page).to have_content(unverified_claim.eligibility.current_school.name)
    expect(page).to have_content(unverified_claim.eligibility.current_school.phone_number)

    choose "Yes"
    click_on "Save and continue"

    expect(unverified_claim.tasks.find_by!(name: "identity_confirmation").passed?).to eq(true)

    click_on "Back"
    click_on "Approve or reject this claim"

    choose "Approve"
    fill_in "Decision notes", with: "Identity confirmed via phone call"
    click_on "Confirm decision"

    expect(unverified_claim.latest_decision.created_by).to eq(@signed_in_user)
    expect(unverified_claim.latest_decision.notes).to eq("Identity confirmed via phone call")
  end
end
