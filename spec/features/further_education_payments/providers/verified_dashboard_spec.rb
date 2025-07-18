require "rails_helper"

RSpec.describe "Provider verified claims dashboard", feature_flag: :provider_dashboard do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  scenario "when no claims" do
    visit "/further-education-payments/providers/verified-claims"
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: "12345678"
    click_button "Start now"

    expect(page).to have_text "Verified claims"
    expect(page).to have_selector("table tbody tr", count: 0)
  end

  scenario "when provider has verified claims" do
    school = create(:school, :fe_eligible, ukprn: "12345678")

    eligibility1 = create(
      :further_education_payments_eligibility,
      :verified,
      school:,
      provider_verification_completed_at: Date.new(2024, 12, 14)
    )
    claim1 = create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility1,
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "C",
      surname: "D"
    )

    eligibility2 = create(
      :further_education_payments_eligibility,
      :verified,
      school:,
      provider_verification_completed_at: Date.new(2024, 12, 14)
    )
    claim2 = create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility2,
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "A",
      surname: "B"
    )

    eligibility3 = create(
      :further_education_payments_eligibility,
      :verified,
      school: create(:school, :fe_eligible, ukprn: "87654321"),
      provider_verification_completed_at: Date.new(2024, 12, 14)
    )
    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility3,
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "Claimant",
      surname: "From Another Provider"
    )

    visit "/further-education-payments/providers/verified-claims"
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: "12345678"
    click_button "Start now"

    click_link "Verified claims"

    expect(page).not_to have_text("Claimant From Another Provider")

    expect(page).to have_text "Verified claims"
    expect(page).to have_selector("table tbody tr", count: 2)

    expect(page).to have_selector("table tbody tr:first-child td:nth-child(1)", text: "A B")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(2)", text: claim2.reference)
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(3)", text: "14 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(4)", text: "Not implemented")

    expect(page).to have_selector("table tbody tr:nth-child(2) td:nth-child(1)", text: "C D")
    expect(page).to have_selector("table tbody tr:nth-child(2) td:nth-child(2)", text: claim1.reference)
    expect(page).to have_selector("table tbody tr:nth-child(2) td:nth-child(3)", text: "14 December 2024")
    expect(page).to have_selector("table tbody tr:nth-child(2) td:nth-child(4)", text: "Not implemented")
  end
end
