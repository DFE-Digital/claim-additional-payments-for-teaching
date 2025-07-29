require "rails_helper"

RSpec.describe "Provider unverified claims dashboard", feature_flag: :provider_dashboard do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  scenario "when no claims" do
    visit "/further-education-payments/providers/claims"
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: "12345678"
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

    other_eligibility = create(
      :further_education_payments_eligibility,
      school: create(:school, :fe_eligible, ukprn: "87654321")
    )
    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: other_eligibility,
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "Claimant",
      surname: "From Another Provider"
    )

    visit "/further-education-payments/providers/claims"
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: "12345678"
    click_button "Start now"

    expect(page).not_to have_text("Claimant From Another Provider")
    expect(page).to have_text "Unverified claims"
    expect(page).to have_selector("table tbody tr", count: 1)
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(1)", text: "Jo Bloggs")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(2)", text: "13 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(3)", text: "27 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(4)", text: "Not processed")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(5)", text: "Not started")
  end

  scenario "claims are ordered with unstarted claims first, then by creation date" do
    school = create(:school, :fe_eligible, ukprn: "12345678")

    older_unstarted_eligibility = create(
      :further_education_payments_eligibility,
      school: school,
      provider_verification_started_at: nil
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: older_unstarted_eligibility,
      created_at: 3.days.ago,
      first_name: "Alice",
      surname: "Older"
    )

    newer_unstarted_eligibility = create(
      :further_education_payments_eligibility,
      school: school,
      provider_verification_started_at: nil
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: newer_unstarted_eligibility,
      created_at: 1.day.ago,
      first_name: "Bob",
      surname: "Newer"
    )

    older_started_eligibility = create(
      :further_education_payments_eligibility,
      school: school,
      provider_verification_started_at: 4.days.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: older_started_eligibility,
      created_at: 4.days.ago,
      first_name: "Charlie",
      surname: "OlderStarted"
    )

    newer_started_eligibility = create(
      :further_education_payments_eligibility,
      school: school,
      provider_verification_started_at: 2.days.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: newer_started_eligibility,
      created_at: 2.days.ago,
      first_name: "Diana",
      surname: "NewerStarted"
    )

    visit "/further-education-payments/providers/claims"
    fill_in "UKPRN", with: "12345678"
    click_button "Start now"

    expect(page).to have_selector("table tbody tr", count: 4)

    expect(page).to have_selector(
      "table tbody tr:nth-child(1) td:nth-child(1)",
      text: "Alice Older"
    )

    expect(page).to have_selector(
      "table tbody tr:nth-child(2) td:nth-child(1)",
      text: "Bob Newer"
    )

    expect(page).to have_selector(
      "table tbody tr:nth-child(3) td:nth-child(1)",
      text: "Charlie OlderStarted"
    )

    expect(page).to have_selector(
      "table tbody tr:nth-child(4) td:nth-child(1)",
      text: "Diana NewerStarted"
    )
  end
end
