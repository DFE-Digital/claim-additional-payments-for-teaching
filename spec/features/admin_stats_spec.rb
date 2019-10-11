require "rails_helper"

RSpec.feature "Admin stats" do
  before do
    @submitted_claims = create_list(:claim, 6, :submitted)
    @approved_claims = create_list(:claim, 4, :approved)
    @unfinished_claims = create_list(:claim, 1, :submittable)
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    visit admin_root_path
  end

  scenario "Service operator is shown how many claims have been submitted" do
    expect(page).to have_text("Total claims received\n#{Claim.submitted.count}")
  end

  scenario "Service operator is shown how many claims are waiting to be checked" do
    expect(page).to have_text("Claims awaiting checking\n#{Claim.awaiting_checking.count}")
  end
end