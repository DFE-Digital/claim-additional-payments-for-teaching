require "rails_helper"

RSpec.describe "Provider verified claims dashboard", feature_flag: :provider_dashboard do
  before do
    allow(DfESignIn).to receive(:bypass?).and_return(true)
  end

  scenario "viewing a verified claim" do
    school = create(:school, :fe_eligible, ukprn: "10000952")
    eligibility = create(
      :further_education_payments_eligibility,
      :verified,
      :provider_verification_completed,
      school:,
      provider_verification_completed_at: Date.new(2024, 12, 14)
    )
    claim = create(
      :claim,
      :further_education,
      :submitted,
      eligibility:,
      submitted_at: Date.new(2024, 12, 13),
      created_at: Date.new(2024, 12, 13),
      first_name: "A",
      surname: "B"
    )

    visit "/further-education-payments/providers/verified-claims"
    expect(page).to have_text "Sign in"
    click_button "Start now"

    click_link "Verified claims"

    click_link claim.full_name

    expect(page).to have_text "Claim reference: #{claim.reference}"

    # role and experience
    expect(page).to have_summary_item(
      key: "Teaching responsibilities",
      value: "Yes"
    )
    expect(page).to have_summary_item(
      key: "In first 5 years of FE teaching",
      value: "Yes"
    )
    expect(page).to have_summary_item(
      key: "Teaching qualification",
      value: "Yes"
    )
    expect(page).to have_summary_item(
      key: "Type of contract",
      value: "Fixed term"
    )
    expect(page).to have_summary_item(
      key: "Contract covers full academic year",
      value: "Yes"
    )

    # performance and discipline
    expect(page).to have_summary_item(
      key: "Subject to performance measures",
      value: "No"
    )
    expect(page).to have_summary_item(
      key: "Subject to disciplinary action",
      value: "No"
    )

    # contracted hours
    expect(page).to have_summary_item(
      key: "Timetabled hours per week",
      value: "20 hours or more each week"
    )
    expect(page).to have_summary_item(
      key: "Teaches 16-19-year-olds or those with EHCP",
      value: "Yes"
    )
    expect(page).to have_summary_item(
      key: "Spend at least half timetabled teaching time teaching relevant courses",
      value: "Yes"
    )
  end
end
