require "rails_helper"

RSpec.feature "Admin checking a claim with personal data removed" do
  before { sign_in_as_service_operator }

  scenario "the service operator sees that the personal data has been removed" do
    claim_with_personal_data_removed = create(:claim, :rejected, :personal_data_removed)

    visit admin_claim_path(claim_with_personal_data_removed)
    expect(page).to have_content("personal data removed")
    expect(page).to have_content("Full name Removed")
    expect(page).to have_content("Date of birth Removed")
    expect(page).to have_content("National Insurance number Removed")
    expect(page).to have_content("Address Removed")
  end
end
