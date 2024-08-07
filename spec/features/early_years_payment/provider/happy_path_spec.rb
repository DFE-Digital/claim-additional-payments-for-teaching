require "rails_helper"

RSpec.feature "Early years payment provider" do
  scenario "happy path claim" do
    when_early_years_payment_provider_journey_configuration_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Declaration of Employee Consent")
    check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"
  end
end
