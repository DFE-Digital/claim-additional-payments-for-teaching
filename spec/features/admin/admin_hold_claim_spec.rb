require "rails_helper"

RSpec.feature "Admin holds a claim" do
  let!(:claim) { create(:claim, :submitted) }

  before do
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "Service operator amends a claim" do
    visit admin_claim_tasks_path(claim)

    expect(page).to have_summary_item key: "Status", value: "Awaiting decision - not on hold"

    within ".app-task-list" do
      expect(page).not_to have_text "On Hold"
    end

    click_on "Notes and support"

    click_button "Save on hold status"

    expect(page).to have_summary_error "Enter why you are putting the claim on hold"

    freeze_time do
      fill_in "On hold", with: "test"
      click_button "Save on hold status"

      expect(page).to have_text "Claim put on hold: test\nby #{@signed_in_user.full_name} on #{Time.zone.now.strftime("%-d %B %Y")}"
    end

    expect(page).to have_summary_item key: "Status", value: "Awaiting decision - on hold"

    click_on "Tasks"

    within ".app-task-list" do
      expect(page).to have_text "On Hold"
      click_on "Approve or reject this claim"
    end

    expect(page).to have_text "You cannot approve or reject a claim that is on hold"
    expect(page.find("#decision_approved_true")).to be_disabled
    expect(page.find("#decision_approved_false")).to be_disabled

    click_on "Back"
    click_on "Notes and support"

    freeze_time do
      click_button "Remove on hold status"

      expect(page).to have_text "Claim hold removed\nby #{@signed_in_user.full_name} on #{Time.zone.now.strftime("%-d %B %Y")}"
    end

    expect(page).to have_summary_item key: "Status", value: "Awaiting decision - not on hold"

    click_on "Tasks"

    within ".app-task-list" do
      expect(page).not_to have_text "On Hold"
      click_on "Approve or reject this claim"
    end

    expect(page).to have_button "Confirm decision"

    choose "Approve"
    click_button "Confirm decision"

    visit admin_claim_tasks_path(claim)
    click_on "Notes and support"

    expect(page).not_to have_text "On hold"
  end
end
