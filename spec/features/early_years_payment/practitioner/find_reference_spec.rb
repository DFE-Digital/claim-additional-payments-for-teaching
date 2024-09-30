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
    expect(page).to have_content "Track your application"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"

    expect(page).to have_content "Track your application"
  end

  scenario "after multiple attempts should work" do
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=user@example.com"
    expect(page).to have_content "Track your application"
    fill_in "Claim reference number", with: "foo"
    click_button "Submit"

    expect(page).to have_content "Track your application"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"

    expect(page).to have_content "login page goes here"
  end
end