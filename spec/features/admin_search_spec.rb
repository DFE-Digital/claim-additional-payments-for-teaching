require "rails_helper"

RSpec.feature "Admin search" do
  before do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  it "redirects to the claim" do
    claim = create(:claim, :submitted)

    visit search_admin_claims_path

    fill_in :reference, with: claim.reference
    click_on "Search"

    expect(page).to have_content(claim.reference)
  end
end
