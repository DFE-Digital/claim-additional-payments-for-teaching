require "rails_helper"

RSpec.feature "Early years payment provider" do
  scenario "view consent form" do
    when_early_years_payment_provider_start_journey_configuration_exists

    visit guidance_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
    click_link "Start now"

    # landing page
    expect(page).to have_text("Employee eligibility")
    all("a", text: "consent form").sample.click

    expect(page).to have_text("We need your consent to share your personal details")
  end
end
