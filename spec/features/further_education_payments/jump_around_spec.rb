require "rails_helper"

RSpec.feature "Further education payments" do
  scenario "visiting impermissible slug redirects back to last permissible slug" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, slug: "address")

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
  end
end
