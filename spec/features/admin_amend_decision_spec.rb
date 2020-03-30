require "rails_helper"

RSpec.feature "Undoing a claim's decision" do
  let(:claim) { create(:claim, :rejected) }
  let(:service_operator) { create(:dfe_signin_user, given_name: "Jo", family_name: "Bloggs") }

  scenario "Service operator can undo a claim's decision" do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, service_operator.dfe_sign_in_id)

    visit admin_claim_url(claim)

    click_on "Amend claim"
    click_on "Undo decision"

    fill_in "Change notes", with: "Here are some notes"

    expect { click_on "Undo rejection" }.to change { claim.reload.amendments.size }.by(1)

    expect(claim.decisions.last.undone?).to eq(true)

    amendment = claim.amendments.last

    expect(amendment.claim).to eq(claim)
    expect(amendment.notes).to eq("Here are some notes")
    expect(amendment.claim_changes).to eq({decision: ["rejected", "undecided"]})

    click_on "Claim amendments"

    expect(page).to have_content("Decision\nchanged from rejected to undecided")
    expect(page).to have_content("Change notes\nHere are some notes")
  end
end
