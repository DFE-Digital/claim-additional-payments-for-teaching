require "rails_helper"

RSpec.describe "Provider unverified claims dashboard" do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
    create(:journey_configuration, :further_education_payments)
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
    eligibility = create(:further_education_payments_eligibility, :eligible, school:)
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
      :eligible,
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
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(5)", text: "Overdue")
  end

  scenario "when there are unverified claims that have repeat_applicant_check_passed=false/nil they are excluded" do
    school = create(:school, :fe_eligible, ukprn: "12345678")

    # repeat_applicant_check_passed = true
    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: create(:further_education_payments_eligibility, :eligible, school:),
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13)
    )

    # repeat_applicant_check_passed = false
    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: create(:further_education_payments_eligibility, :eligible, repeat_applicant_check_passed: false, school:),
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "Flagged",
      surname: "Claimant"
    )

    # repeat_applicant_check_passed = nil
    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: create(:further_education_payments_eligibility, :eligible, repeat_applicant_check_passed: nil, school:),
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "Flagged2",
      surname: "Claimant2"
    )

    visit "/further-education-payments/providers/claims"
    expect(page).to have_text "Sign in"
    fill_in "UKPRN", with: "12345678"
    click_button "Start now"

    expect(page).not_to have_text("Flagged Claimant")
    expect(page).not_to have_text("Flagged2 Claimant2")

    expect(page).to have_text "Unverified claims"
    expect(page).to have_selector("table tbody tr", count: 1)
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(1)", text: "Jo Bloggs")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(2)", text: "13 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(3)", text: "27 December 2024")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(4)", text: "Not processed")
    expect(page).to have_selector("table tbody tr:first-child td:nth-child(5)", text: "Overdue")
  end

  scenario "claims are ordered by creation (due) date" do
    school = create(:school, :fe_eligible, ukprn: "12345678")

    alice_eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_started_at: nil
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: alice_eligibility,
      created_at: 5.days.ago,
      first_name: "Alice",
      surname: "Oldest"
    )

    bob_eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_started_at: nil
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: bob_eligibility,
      created_at: 4.day.ago,
      first_name: "Bob",
      surname: "Old"
    )

    charlie_eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_started_at: 2.days.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: charlie_eligibility,
      created_at: 3.days.ago,
      first_name: "Charlie",
      surname: "New"
    )

    diana_eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      school: school,
      provider_verification_started_at: 1.day.ago
    )

    create(
      :claim,
      :further_education,
      :submitted,
      eligibility: diana_eligibility,
      created_at: 2.days.ago,
      first_name: "Diana",
      surname: "Newest"
    )

    visit "/further-education-payments/providers/claims"
    fill_in "UKPRN", with: "12345678"
    click_button "Start now"

    expect(page).to have_selector("table tbody tr", count: 4)

    expect(page).to have_selector(
      "table tbody tr:nth-child(1) td:nth-child(1)",
      text: "Alice Oldest"
    )

    expect(page).to have_selector(
      "table tbody tr:nth-child(2) td:nth-child(1)",
      text: "Bob Old"
    )

    expect(page).to have_selector(
      "table tbody tr:nth-child(3) td:nth-child(1)",
      text: "Charlie New"
    )

    expect(page).to have_selector(
      "table tbody tr:nth-child(4) td:nth-child(1)",
      text: "Diana Newest"
    )
  end
end
