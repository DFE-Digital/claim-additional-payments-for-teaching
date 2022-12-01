require "rails_helper"

RSpec.feature "Admin holds a claim" do
  let!(:claim) { create(:claim, :submitted) }

  before do
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "Service operator amends a claim" do
    visit admin_claim_tasks_path(claim)

    within ".app-task-list" do
      expect(page).not_to have_text "On Hold"
    end

    click_on "Notes and support"

    click_button "Save on hold status"

    expect(page).to have_text "There is a problem"
    expect(page).to have_text "Enter why you are putting the claim on hold"

    freeze_time do
      fill_in "On hold", with: "test"
      click_button "Save on hold status"

      expect(page).to have_text "Claim put on hold: test\nby #{@signed_in_user.full_name} on #{Time.zone.now.strftime("%-d %B %Y")}"
    end

    click_on "Tasks"

    within ".app-task-list" do
      expect(page).to have_text "On Hold"
      click_on "Approve or reject this claim"
    end

    expect(page).to have_text "You cannot approve or reject a claim that is on hold"
    expect(page.find("#decision_result_approved")).to be_disabled
    expect(page.find("#decision_result_rejected")).to be_disabled

    click_on "Back"
    click_on "Notes and support"

    freeze_time do
      click_button "Remove on hold status"

      expect(page).to have_text "Claim hold removed\nby #{@signed_in_user.full_name} on #{Time.zone.now.strftime("%-d %B %Y")}"
    end

    click_on "Tasks"

    within ".app-task-list" do
      expect(page).not_to have_text "On Hold"
      click_on "Approve or reject this claim"
    end

    expect(page).to have_button "Confirm decision"
  end
end
