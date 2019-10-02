require "rails_helper"

RSpec.feature "Admin sessions" do
  before do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  scenario "Redirected to admin page after signing in" do
    expect(page).to have_content("Admin")
  end

  scenario "Signing out" do
    click_on "Sign out"
    expect(page).to have_content("You've been signed out")
  end
end
