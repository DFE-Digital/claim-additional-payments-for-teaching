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
end
