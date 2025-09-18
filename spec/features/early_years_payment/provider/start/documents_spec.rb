require "rails_helper"

RSpec.feature "Early years payment provider" do
  scenario "view consent form" do
    when_early_years_payment_provider_start_journey_configuration_exists

    # guidance page
    visit guidance_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
    click_link "start the claim on behalf of the early years educator"

    # landing page
    expect(page).to have_text("Claim an early years financial incentive payment on behalf of your employee")
    all("a", text: "consent form").sample.click

    expect(page).to have_text("We need your consent to share your personal details")
  end
end
