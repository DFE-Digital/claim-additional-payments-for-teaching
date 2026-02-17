require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:school) { create(:school, :fe_eligible) }
  let(:college) { school }
  let(:expected_award_amount) { college.eligible_fe_provider.max_award_amount }

  scenario "visiting impermissible slug redirects back to last permissible slug" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")

    visit claim_path(Journeys::FurtherEducationPayments.routing_name, slug: "address")

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
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

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose school.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have")
    choose "Permanent"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach")
    choose "Fewer than 2.5 hours each week"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")

    visit claim_path(Journeys::FurtherEducationPayments.routing_name, "contract-type")
    expect(page).to have_content("What type of contract do you have")
    choose "Fixed-term"
    click_button "Continue"

    expect(page).not_to have_content "You are not eligible"
  end

  scenario "changing subjects" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose school.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have")
    choose "Permanent"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach")
    choose "12 or more hours per week, but fewer than 20"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
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

    visit claim_path(Journeys::FurtherEducationPayments.routing_name, slug: "subjects-taught")
    uncheck "Chemistry"
    click_button "Continue"

    expect(Journeys::FurtherEducationPayments::Session.count).to eql(1)
    expect(Journeys::FurtherEducationPayments::Session.last.answers.chemistry_courses).to be_empty

    expect(page).to have_content("Which computing courses do you teach?")
  end

  scenario "postcode search address and selects a result" do
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have directly with #{college.name}?")
    choose("Permanent")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the spring term?")
    choose("12 or more hours per week, but fewer than 20")
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in building services engineering for construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    expect(page).to have_content("T Level in building services engineering for construction")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you currently subject to any formal performance measures as a result of continuous poor teaching standards")
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    expect(page).to have_content("Are you currently subject to disciplinary action?")
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_button "Continue"

    expect(page).to have_content("Check your answers")
    click_button "Continue"

    expect(page).to have_content("You’re eligible for a targeted retention incentive payment")
    expect(page).to have_content(number_to_currency(expected_award_amount, precision: 0))
    expect(page).to have_content("Apply now")
    click_button "Apply now"

    sign_in_with_one_login
    idv_with_one_login

    expect(page).to have_content("How we will use your information")
    expect(page).to have_content("the Student Loans Company")
    click_button "Continue"

    expect(page).to have_content("Personal details")
    expect(page).to have_content("Enter your National Insurance number")
    fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
    click_on "Continue"

    stub_search_places_index(claim: OpenStruct.new(postcode: "SO16 9FX"))

    expect(page).to have_content("What is your home address?")
    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    expect(page).to have_text "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_on "Continue"

    expect(page).to have_content("Email address")
  end

  scenario "postcode search address but result not in list" do
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    expect(page).to have_content("Are you a member of staff with the responsibilities of a teacher?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have directly with #{college.name}?")
    choose("Permanent")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the spring term?")
    choose("12 or more hours per week, but fewer than 20")
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in building services engineering for construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    expect(page).to have_content("T Level in building services engineering for construction")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you currently subject to any formal performance measures as a result of continuous poor teaching standards")
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    expect(page).to have_content("Are you currently subject to disciplinary action?")
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_button "Continue"

    expect(page).to have_content("Check your answers")
    click_button "Continue"

    expect(page).to have_content("You’re eligible for a targeted retention incentive payment")
    expect(page).to have_content(number_to_currency(expected_award_amount, precision: 0))
    expect(page).to have_content("Apply now")
    click_button "Apply now"

    sign_in_with_one_login
    idv_with_one_login

    expect(page).to have_content("How we will use your information")
    expect(page).to have_content("the Student Loans Company")
    click_button "Continue"

    expect(page).to have_content("Personal details")
    expect(page).to have_content("Enter your National Insurance number")
    fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
    click_on "Continue"

    stub_search_places_index(claim: OpenStruct.new(postcode: "SO16 9FX"))

    expect(page).to have_content("What is your home address?")
    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    expect(page).to have_text "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_button "I can’t find my address in the list"

    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(page).to have_content("Email address")
  end

  def and_college_exists
    school
  end
end
