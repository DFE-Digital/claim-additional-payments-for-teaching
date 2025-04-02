require "rails_helper"

RSpec.feature "Admin session management" do
  scenario "A user is redirected to the admin root path after sign in" do
    sign_in_as_service_operator

    expect(page).to have_link("Sign out")
    expect(current_path).to eql(admin_root_path)

    # - A signed in user can sign out

    click_on "Sign out"

    expect(page).to have_content("You've been signed out")
    expect(current_path).to eql(admin_sign_in_path)
  end

  scenario "A user is redirected to their original url after sign in" do
    visit admin_claims_path

    expect(current_path).to eql(admin_sign_in_path)

    sign_in_as_service_operator

    expect(current_path).to eql(admin_claims_path)
  end

  scenario "accepting cookies does not affect sign in" do
    visit admin_sign_in_path
    click_button "Accept additional cookies"
    click_button "Hide cookie message"

    sign_in_as_service_operator

    expect(page).to have_content "Claims received"
  end
end
