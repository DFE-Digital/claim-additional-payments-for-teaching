require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims", js: true do
  let(:one_second_in_minutes) { 1 / 60.to_f }
  let(:two_seconds_in_minutes) { 2 / 60.to_f }

  before do
    allow_any_instance_of(ApplicationController).to receive(:claim_timeout_in_minutes) { two_seconds_in_minutes }
    allow_any_instance_of(ApplicationController).to receive(:claim_timeout_warning_in_minutes) { one_second_in_minutes }
    start_claim
  end

  scenario "Dialog warns claimants their session will timeout" do
    expect(page).to have_content("Your session will expire in #{one_second_in_minutes} minutes")
    expect(page).to have_button("Continue session")
  end

  scenario "Claimants can refresh their session" do
    expect(page).to have_content("Your session will expire in #{one_second_in_minutes} minutes")
    expect_any_instance_of(SessionsController).to receive(:update_last_seen_at)
    click_on "Continue session"
  end

  scenario "Claimants are automatically redirected to the timeout page" do
    wait_until_visible { find("h1", text: "Your session has ended due to inactivity") }
    expect(current_path).to eql(timeout_claim_path)
  end
end
