require "rails_helper"

RSpec.feature "Further education payments" do
  scenario "when searching for college that could not be found" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Have you previously")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: "foo"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    expect(page).to have_content("No results match that search term. Try again.")
  end

  scenario "when searching for college that could not be found with js", js: true, flaky: true do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Have you previously")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: "foo"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    expect(page).to have_content("No results match that search term. Try again.")
  end
end
