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

  scenario "when teacher is subject to performance measures" do
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
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    click_button "Continue"

    expect(page).to have_content("FE building and construction courses goes here")
    click_button "Continue"

    expect(page).to have_content("FE teaching courses goes here")
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Have any performance measures been started against you?")
    within all(".govuk-fieldset")[0] do
      choose("Yes")
    end
    expect(page).to have_content("Are you currently subject to disciplinary action?")
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must not currently be subject to any")
  end

  scenario "when teacher is subject to disciplinary action" do
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
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    click_button "Continue"

    expect(page).to have_content("FE building and construction courses goes here")
    click_button "Continue"

    expect(page).to have_content("FE teaching courses goes here")
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Have any performance measures been started against you?")
    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    expect(page).to have_content("Are you currently subject to disciplinary action?")
    within all(".govuk-fieldset")[1] do
      choose("Yes")
    end
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must not currently be subject to any")
  end

  scenario "when lacks teaching qualification and no enrol plan" do
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
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    click_button "Continue"

    expect(page).to have_content("FE building and construction courses goes here")
    click_button "Continue"

    expect(page).to have_content("FE teaching courses goes here")
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose "No, and I do not plan to enrol on one in the next 12 months"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("plan to enrol on a teaching qualification in the next 12 months")
  end

  scenario "when permanent contract and not enough hours" do
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
    choose("Less than 2.5 hours per week")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("teach at least 2.5 hours per week")
  end

  scenario "when fixed-term contract and not enough hours" do
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
    choose("Yes, it covers the full #{current_academic_year.to_s(:long)} academic year")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?")
    choose("More than 12 hours per week")
    click_button "Continue"

    expect(page).to have_content("Are you timetabled to teach at least 2.5 hours per week at #{college.name} next term?")
    choose("No, I’m not timetabled to teach at least 2.5 hours at #{college.name} next term")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("teach at least 2.5 hours per week")
  end

  scenario "when variable contract and not enough hours" do
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
    choose("Yes, I have taught at #{college.name} for at least one academic term")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?")
    choose("More than 12 hours per week")
    click_button "Continue"

    expect(page).to have_content("Are you timetabled to teach at least 2.5 hours per week at #{college.name} next term?")
    choose("No, I’m not timetabled to teach at least 2.5 hours at #{college.name} next term")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("teach at least 2.5 hours per week")
  end

  def when_further_education_payments_journey_configuration_exists
    create(:journey_configuration, :further_education_payments)
  end

  def and_college_exists
    college
  end
end
