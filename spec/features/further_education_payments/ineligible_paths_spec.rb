require "rails_helper"

RSpec.feature "Further education payments ineligible paths" do
  scenario "when no teaching responsibilities" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be employed as a member of staff with teaching responsibilities")
  end

  def when_further_education_payments_journey_configuration_exists
    create(:journey_configuration, :further_education_payments)
  end
end
