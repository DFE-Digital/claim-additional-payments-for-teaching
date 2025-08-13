require "rails_helper"

RSpec.feature "Further education payments" do
  scenario "when searching for college that could not be found" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Check you’re eligible for a targeted retention incentive payment for further education")
    expect(page).to have_content("Answer the questions in the next section")
    click_button "Start eligibility check"

    expect(page).to have_content("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: "foo"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    expect(page).to have_content("No results match that search term. Try again.")
  end

  scenario "when searching for college that could not be found with js", js: true, flaky: true do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Check you’re eligible for a targeted retention incentive payment for further education")
    expect(page).to have_content("Answer the questions in the next section")
    click_button "Start eligibility check"

    expect(page).to have_content("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: "foo"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    expect(page).to have_content("No results match that search term. Try again.")
  end
end
