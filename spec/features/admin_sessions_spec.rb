require "rails_helper"

RSpec.feature "Admin sessions" do
  before do
    allow_any_instance_of(DfeSignIn::UserAccess).to receive(:has_role?) { true }
  end

  scenario "Redirected to admin page after signing in" do
    visit admin_path
    click_on "Sign in"

    expect(page).to have_content("Admin")
  end

  scenario "Signing out" do
    visit admin_path
    click_on "Sign in"

    click_on "Sign out"
    expect(page).to have_content("You've been signed out")
  end
end
