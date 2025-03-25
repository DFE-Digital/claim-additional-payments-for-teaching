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
  end

  context "when claim is high risk" do
    let(:claim) do
      create(:claim, :rejected, :high_risk)
    end

    scenario "service operator cannot undo high risk claim decisions" do
      current_admin = sign_in_as_service_operator

      visit admin_claim_url(claim)
      click_link "Amend claim"

      click_link "Undo decision"

      expect(page).to have_content "This decision cannot be undone"
      expect(page).to have_field("amendment-notes-field", disabled: true)
    end

    scenario "service admin can undo high risk claim decisions" do
      current_admin = sign_in_as_service_admin

      visit admin_claim_url(claim)
      click_link "Amend claim"

      click_link "Undo decision"

      expect(page).not_to have_content "This decision cannot be undone"
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
      expect(page).to have_content("by #{current_admin.full_name}")
    end
  end
end
