require "rails_helper"

RSpec.feature "Manager admin users" do
  scenario "change roles" do
    admin = sign_in_as_service_admin
    visit admin_users_path
    expect(page).to have_text "Manage users"
    click_link "Aaron Admin"

    check "Payroll"
    expect {
      click_button "Save"
    }.to change { admin.reload.roles }.from([]).to(["payroll"])

    expect(page).to have_text "Manage users"
    expect(page).to have_text ["Aaron Admin", "aaron.admin@education.gov.uk",	"1"].join
  end
end
