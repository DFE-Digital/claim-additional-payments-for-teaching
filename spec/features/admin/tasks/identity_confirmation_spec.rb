require "rails_helper"

RSpec.feature "Admin performs identity confirmation task" do
  let(:claim) { create(:claim, :submitted, :with_onelogin_idv_data, policy: Policies::FurtherEducationPayments) }

  before do
    disable_claim_qa_flagging
    sign_in_as_service_operator
  end

  scenario "when user used One Login IDV" do
    claim

    visit admin_claims_path
    click_link claim.reference
    click_link "Confirm the claimant made the claim"

    expect(page).to have_content "This task was performed by GOV.UK One Login on #{I18n.localize(claim.onelogin_idv_at)}"
  end
end
