require "rails_helper"

RSpec.describe "Provider unverified claims dashboard", feature_flag: :provider_dashboard do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  scenario "when no claims" do
    visit "/further-education-payments/providers/claims"
    expect(page).to have_text "Sign in"
    click_button "Start now"

    expect(page).to have_text "Unverified claims"
    expect(page).to have_selector("table tbody tr", count: 0)
  end

  scenario "when provider has an unverified claim" do
    school = create(:school, :fe_eligible, ukprn: "12345678")
    eligibility = create(:further_education_payments_eligibility, school:)
    create(
      :claim,
      :further_education,
      :submitted,
      eligibility:,
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13)
    )

    visit "/further-education-payments/providers/claims"
    expect(page).to have_text "Sign in"
    click_button "Start now"

    expect(page).to have_text "Unverified claims"
    expect(page).to have_selector("table tbody tr", count: 1)
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(1)", text: "Jo Bloggs")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(2)", text: "13 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(3)", text: "27 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(4)", text: "Unassigned")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(5)", text: "Not started")
  end
end
