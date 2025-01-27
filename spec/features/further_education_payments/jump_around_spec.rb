require "rails_helper"

RSpec.feature "Further education payments" do
  let(:school) { create(:school, :fe_eligible) }

  scenario "visiting impermissible slug redirects back to last permissible slug" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, slug: "address")

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
  end

  # user reaches an ineligible state
  # hits back button more than once
  # changes an answer that does not change pathway
  # ie they are still inelgibile
  # we remove the ineligible answer
  # so they can continue with their current journey
  # rather than still showing an ineligible page again
  scenario "changing answer on a previous page that maintains pathway" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose school.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach")
    choose "Less than 2.5 hours per week"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, "contract-type")
    expect(page).to have_content("What type of contract do you have")
    choose "Fixed-term contract"
    click_button "Continue"

    expect(page).not_to have_content "You are not eligible"
  end
end
