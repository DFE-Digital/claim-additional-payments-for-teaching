require "rails_helper"

RSpec.feature "Admin checking a claim with personal data removed" do
  before { sign_in_as_service_operator }

  scenario "the service operator sees that personal data has been removed from the full claim view" do
    claim_with_personal_data_removed = create(:claim, :rejected, :personal_data_removed)

    visit admin_claim_path(claim_with_personal_data_removed)
    expect(page).to have_content("personal data removed")
    expect(page).to have_content("Full name Removed")
    expect(page).to have_content("Date of birth Removed")
    expect(page).to have_content("National Insurance number Removed")
    expect(page).to have_content("Address Removed")
  end

  scenario "the service operator sees that personal data has been removed from the view on tasks page" do
    claim_with_personal_data_removed = create(:claim, :rejected, :personal_data_removed)

    visit admin_claim_path(claim_with_personal_data_removed)

    click_on "View tasks"

    expect(page).to have_content("Full name Removed")
    expect(page).to have_content("Date of birth Removed")
    expect(page).to have_content("NI number Removed")
  end
end
