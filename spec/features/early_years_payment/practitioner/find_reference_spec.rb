require "rails_helper"

RSpec.feature "Early years find reference" do
  let(:claim) do
    create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      reference: "foo",
      practitioner_email_address: "user@example.com"
    )
  end

  scenario "when correct email address with different case" do
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=USER@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"

    expect(page).to have_content "Sign in with GOV.UK One Login"
  end

  scenario "when different email address" do
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=other@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"

    expect(page).to have_content "This claim reference isn’t correct."
  end

  scenario "after multiple attempts should work" do
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=user@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"

    expect(page).to have_content "Sign in with GOV.UK One Login"
    click_link "Back"

    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"
    expect(page).to have_content "Sign in with GOV.UK One Login"
  end

  scenario "should show ineligibility page when an invalid reference is given" do
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=user@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: "invalid"
    click_button "Submit"

    expect(page).to have_content "This claim reference isn’t correct."
    click_link "Try again"

    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: "also invalid"
    click_button "Submit"

    expect(page).to have_content "This claim reference isn’t correct."
    click_link "Back"

    expect(page).to have_content "Enter your claim reference"
  end

  context "when the claim is already submitted" do
    let(:eligible_ey_provider) { create(:eligible_ey_provider, nursery_name: "Test Nursery") }

    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::EarlyYearsPayments,
        eligibility: build(:early_years_payments_eligibility, nursery_urn: eligible_ey_provider.urn),
        reference: "foo",
        practitioner_email_address: "user@example.com"
      )
    end

    scenario "should show ineligibility page when a submitted claim reference is given" do
      when_early_years_payment_practitioner_journey_configuration_exists

      visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=user@example.com"
      expect(page).to have_content "Enter your claim reference"
      fill_in "Claim reference number", with: claim.reference
      click_button "Submit"

      expect(page).to have_content "You've already submitted your claim"
      expect(page).to have_content "After 6 months in your role, we'll check that you’re still working at Test Nursery."

      click_link "Back"
      expect(page).to have_content "Enter your claim reference"
    end
  end
end
