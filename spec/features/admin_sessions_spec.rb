require "rails_helper"

RSpec.feature "Admin session management" do
  scenario "A user is redirected to the admin root path after sign in" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    expect(page).to have_link("Sign out")
    expect(current_path).to eql(admin_root_path)
  end

  scenario "A signed in user can sign out" do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

    click_on "Sign out"
    expect(page).to have_content("You've been signed out")
    expect(current_path).to eql(admin_sign_in_path)
  end
end
