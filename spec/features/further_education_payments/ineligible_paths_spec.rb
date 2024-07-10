require "rails_helper"

RSpec.feature "Further education payments ineligible paths" do
  let(:school) { create(:school, :further_education) }
  let(:college) { school }
  let(:current_academic_year) { AcademicYear.current }

  scenario "when no teaching responsibilities" do
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be employed as a member of staff with teaching responsibilities")
  end

  scenario "when fixed term contract and just one academic term taught" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select the college you teach at")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{college.name}?")
    choose("Fixed-term contract")
    click_button "Continue"

    expect(page).to have_content("Does your fixed-term contract cover the full #{current_academic_year.to_s(:long)} academic year?")
    choose("No, it does not cover the full #{current_academic_year.to_s(:long)} academic year")
    click_button "Continue"

    expect(page).to have_content("Have you taught at #{college.name} for at least one academic term?")
    choose("No, I have not taught at #{college.name} for at least one academic term")
    click_button "Continue"

    expect(page).to have_content("You are not eligible for a financial incentive payment yet")
  end

  scenario "when variable contract and just one academic term taught" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select the college you teach at")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{college.name}?")
    choose("Variable hours contract")
    click_button "Continue"

    expect(page).to have_content("Have you taught at #{college.name} for at least one academic term?")
    choose("No, I have not taught at #{college.name} for at least one academic term")
    click_button "Continue"

    expect(page).to have_content("You are not eligible for a financial incentive payment yet")
  end

  scenario "when not a recent FE teacher" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select the college you teach at")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{college.name}?")
    choose("Permanent contract")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?")
    choose("More than 12 hours per week")
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose("I started before September #{current_academic_year.start_year - 4}")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be in the first 5 years of")
  end

  def when_further_education_payments_journey_configuration_exists
    create(:journey_configuration, :further_education_payments)
  end

  def and_college_exists
    college
  end
end
