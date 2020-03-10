require "rails_helper"

RSpec.feature "Admin checking a claim with personal data removed" do
  let(:user) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
  end

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
