require "rails_helper"

RSpec.describe "Approvals" do
  let(:admin) { sign_in_as_service_operator }

  before do
    admin
    create(
      :claim,
      :submitted,
      assigned_to: admin
    )
  end

  scenario "it shows my claims" do
    visit "/admin"
    click_link "My claims"

    expect(page).to have_content "My claims"
    expect(page).to have_css("table tbody tr", count: 1)
  end
end
