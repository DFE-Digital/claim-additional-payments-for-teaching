require "rails_helper"

RSpec.feature "Early years payment" do
  scenario "happy path claim" do
    when_early_years_payment_journey_configuration_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::ROUTING_NAME)
    expect(page).to have_link("Start now")
  end
end
