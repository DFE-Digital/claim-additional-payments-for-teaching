require "rails_helper"

RSpec.feature "Admin sessions" do
  context "when the user is an admin" do
    before do
      stub_dfe_sign_in_with_role(Admin::AuthController::DFE_SIGN_IN_ADMIN_ROLE_CODE)
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

  context "when the user is a support user" do
    before do
      stub_dfe_sign_in_with_role(Admin::AuthController::DFE_SIGN_IN_SUPPORT_ROLE_CODE)
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
end
