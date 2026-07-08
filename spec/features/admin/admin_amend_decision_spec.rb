require "rails_helper"

RSpec.feature "Undoing a claim's decision" do
  let(:claim) { create(:claim, :rejected) }

  before { create(:journey_configuration, :student_loans) }

  scenario "Service operator can undo a claim's decision" do
    signed_in_user = sign_in_as_service_operator

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
    expect(page).to have_content("by #{signed_in_user.full_name}")

    visit new_admin_claim_decision_path(claim)
    choose "Approve"
    click_on "Confirm decision"

    visit admin_claim_url(claim)
    click_on "Amend claim"
    click_on "Undo decision"
    fill_in "Change notes", with: "Here are some notes"
    click_on "Undo approval"

    visit new_admin_claim_decision_path(claim)
    choose "Approve"
    click_on "Confirm decision"

    visit admin_claim_decisions_path(claim)

    within '[data-test-id="decisions-container"]' do
      within ".govuk-summary-list:first-of-type" do
        expect(page).to have_text "Result Rejected (undone)"
      end

      within ".govuk-summary-list:nth-of-type(2)" do
        expect(page).to have_text "Result Approved (undone)"
      end

      within ".govuk-summary-list:last-of-type" do
        expect(page).to have_text "Result Approved"
        expect(page).not_to have_text "undone"
      end
    end
  end
end
