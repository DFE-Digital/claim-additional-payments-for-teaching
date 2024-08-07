require "rails_helper"

RSpec.feature "Admin access" do
  scenario "User is shown a forbidden error when not from an allowed IP" do
    allow_any_instance_of(Rack::Request).to receive(:ip).and_return("1.1.1.1")

    visit admin_root_path

    expect(page.status_code).to eq(403)
    expect(page).to have_content("Forbidden")
  end

  scenario "User is shown the admin page when from an allowed IP" do
    visit admin_root_path

    expect(page.status_code).to eq(200)
    expect(page).to have_content("Sign in with DfE Sign In")
  end
end
