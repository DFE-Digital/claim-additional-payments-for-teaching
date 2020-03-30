require "rails_helper"

RSpec.feature "Admin claim notes" do
  before { @signed_in_user = sign_in_as_service_operator }

  scenario "the service operator adds notes to a claim" do
    claim = create(:claim, :submitted)
    existing_note = create(:note, body: "Some note about claim", claim: claim)

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    click_on "Notes"

    expect(page).to have_content(existing_note.body)
    expect(page).to have_content(existing_note.created_by.full_name)

    fill_in "Add note", with: "No data for this teacher in TPS, needs a manual employment check"
    expect { click_on "Add note" }.to change { claim.notes.count }.by(1)

    note = claim.notes.last
    expect(note.body).to have_content("No data for this teacher in TPS, needs a manual employment check")
    expect(note.created_by).to eq(@signed_in_user)
  end
end
