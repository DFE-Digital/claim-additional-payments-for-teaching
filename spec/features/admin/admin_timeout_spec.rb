require "rails_helper"

RSpec.feature "Admin user session timeout", js: true, flaky: true do
  let(:one_second_in_minutes) { 1 / 60.to_f }
  let(:two_seconds_in_minutes) { 2 / 60.to_f }

  before do
    allow(DfeSignIn::Config.instance).to receive(:bypass?).and_return(true)

    Rails.application.reload_routes!

    allow_any_instance_of(Admin::BaseAdminController).to receive(:admin_timeout_in_minutes) { two_seconds_in_minutes }
    allow_any_instance_of(Admin::BaseAdminController).to receive(:timeout_warning_in_minutes) { one_second_in_minutes }

    visit admin_sign_in_path
    click_button "Sign in as service operator (bypass DfE Sign-in)"
  end

  scenario "Dialog warns user their session will timeout" do
    expect(page).to have_content("Your session will expire in #{one_second_in_minutes} minutes")
    expect(page).to have_button("Continue session")
  end

  scenario "can refresh their session" do
    expect(page).to have_content("Your session will expire in #{one_second_in_minutes} minutes")
    expect_any_instance_of(Admin::SessionsController).to receive(:update_last_seen_at)
    click_on "Continue session"
  end

  scenario "automatically signs out the admin session if no action taken" do
    wait_until_visible { find("h1", text: "Sign in with DfE Sign In") }
    expect(current_path).to eql(admin_sign_in_path)

    visit admin_root_path
    expect(page).to have_content("Sign in with DfE Sign In")
  end
end
