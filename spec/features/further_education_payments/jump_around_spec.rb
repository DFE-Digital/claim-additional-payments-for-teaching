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

  scenario "changing subjects" do
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
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2024 to August 2025"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Chemistry"
    check "Computing, including digital and ICT"
    click_button "Continue"

    expect(Journeys::FurtherEducationPayments::Session.last.answers.chemistry_courses).to be_empty

    expect(page).to have_content("Which chemistry courses do you teach?")
    check "GCSE chemistry"
    click_button "Continue"

    expect(Journeys::FurtherEducationPayments::Session.last.answers.chemistry_courses).not_to be_empty

    expect(page).to have_content("Which computing courses do you teach?")
    check "T Level in digital support services"
    click_button "Continue"

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, slug: "subjects-taught")
    uncheck "Chemistry"
    click_button "Continue"

    expect(Journeys::FurtherEducationPayments::Session.count).to eql(1)
    expect(Journeys::FurtherEducationPayments::Session.last.answers.chemistry_courses).to be_empty

    expect(page).to have_content("Which computing courses do you teach?")
  end
end
