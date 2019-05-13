require "rails_helper"

RSpec.feature "Admin sessions" do
  scenario "Redirected to admin page after signing in" do
    visit admin_path
    click_on "Sign in"

    expect(page).to have_content("Admin")
  end
end
