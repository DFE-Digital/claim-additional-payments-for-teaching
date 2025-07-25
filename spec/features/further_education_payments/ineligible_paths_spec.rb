require "rails_helper"

RSpec.feature "Further education payments ineligible paths" do
  let(:ineligible_college) { create(:school, :further_education) }
  let(:eligible_college) { create(:school, :further_education, :fe_eligible) }
  let(:closed_eligible_college) { create(:school, :further_education, :fe_eligible, :closed) }
  let(:current_academic_year) { AcademicYear.current }

  scenario "when no teaching responsibilities" do
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

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be employed as a member of staff with teaching responsibilities")
  end

  scenario "when ineligible FE provider is selected" do
    when_further_education_payments_journey_configuration_exists
    and_ineligible_college_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: ineligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose ineligible_college.name
    click_button "Continue"

    expect(page).to have_content("The further education (FE) provider you have entered is not eligible")
    click_link "Change FE provider"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
  end

  scenario "when ineligible FE provider is selected with js", js: true, flaky: true do
    when_further_education_payments_journey_configuration_exists
    and_ineligible_college_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: ineligible_college.name
    within("#claim-provision-search-field__listbox") do
      sleep(1) # seems to aid in success, as if click happens before event is bound
      find("li", text: ineligible_college.name).click
    end
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose ineligible_college.name
    click_button "Continue"

    expect(page).to have_content("The further education (FE) provider you have entered is not eligible")
    click_link "Change FE provider"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    within("#claim-provision-search-field__listbox") do
      sleep(1) # seems to aid in success, as if click happens before event is bound
      find("li", text: eligible_college.name).click
    end
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
  end

  scenario "when closed FE provider selected" do
    when_further_education_payments_journey_configuration_exists
    and_closed_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: closed_eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose closed_eligible_college.name
    click_button "Continue"

    expect(page).to have_content("The further education (FE) provider you have entered is not eligible")
    click_link "Change FE provider"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
  end

  scenario "when fixed term contract and just one academic term taught" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose("Fixed-term contract")
    click_button "Continue"

    expect(page).to have_content("Does your fixed-term contract cover the full #{current_academic_year.to_s(:long)} academic year?")
    choose("No, it does not cover the full #{current_academic_year.to_s(:long)} academic year")
    click_button "Continue"

    expect(page).to have_content("Have you taught at #{eligible_college.name} for at least one academic term?")
    choose("No")
    click_button "Continue"

    expect(page).to have_content("You are not eligible for a targeted retention incentive payment yet")
  end

  scenario "when lacking subjects" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2023 to August 2024"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "I do not teach any of these subjects"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must teach an eligible FE subject")
  end

  scenario "when variable contract and just one academic term taught" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose("Variable hours contract")
    click_button "Continue"

    expect(page).to have_content("Have you taught at #{eligible_college.name} for at least one academic term?")
    choose("No")
    click_button "Continue"

    expect(page).to have_content("You are not eligible for a targeted retention incentive payment yet")
  end

  scenario "when teaches non eligible course in applicable subject area" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2023 to August 2024"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Building and construction"
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "I do not teach any of these courses"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must teach an eligible FE course")
  end

  scenario "when teacher spends less than half hours teaching eligible courses" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2023 to August 2024"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Building and construction"
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in onsite construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("In order to claim a targeted retention incentive payment, at least half of your timetabled teaching hours should be spent teaching an")
  end

  scenario "when not a recent FE teacher" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose("Permanent contract")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose("12 hours or more per week")
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose("I started before September #{current_academic_year.start_year - 4}")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be in the first 5 years of")
  end

  scenario "when teacher is subject to performance measures" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2023 to August 2024"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Building and construction"
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in onsite construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you subject to any formal performance measures as a result of continuous poor teaching standards")
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
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2023 to August 2024"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Building and construction"
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in onsite construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you subject to any formal performance measures as a result of continuous poor teaching standards")
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
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2023 to August 2024"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Building and construction"
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in onsite construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "Yes"
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
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose("Less than 2.5 hours per week")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("teach at least 2.5 hours per week")
  end

  scenario "when fixed-term contract and not enough hours" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose "Fixed-term contract"
    click_button "Continue"

    expect(page).to have_content("Does your fixed-term contract cover the full #{current_academic_year.to_s(:long)} academic year?")
    choose "Yes, it covers the full #{current_academic_year.to_s(:long)} academic year"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Are you timetabled to teach at least 2.5 hours per week at #{eligible_college.name} next term?")
    choose("No")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("teach at least 2.5 hours per week")
  end

  scenario "when variable contract and not enough hours" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose("Variable hours contract")
    click_button "Continue"

    expect(page).to have_content("Have you taught at #{eligible_college.name} for at least one academic term?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("Are you timetabled to teach at least 2.5 hours per week at #{eligible_college.name} next term?")
    choose("No")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("teach at least 2.5 hours per week")
  end

  scenario "when less that 50% teaching hours to FE" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Do you have a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Did you apply for a")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider directly employs you?")
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have with #{eligible_college.name}?")
    choose("Permanent contract")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{eligible_college.name} during the current term?")
    choose("12 hours or more per week")
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Building and construction"
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in onsite construction"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("half of your timetabled teaching hours must include")
  end

  scenario "when the claimant has already submitted a claim" do
    previous_claim = create(
      :claim,
      :further_education,
      onelogin_uid: "12345"
    )

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)

    click_link "Start now"

    expect(page).to have_text("Do you have a GOV.UK One Login account")
    choose "No"
    click_button "Continue"

    expect(page).to have_text("Did you apply for a targeted retention incentive payment for your work in further education")
    choose "No"
    click_button "Continue"

    # teaching-responsibilities
    choose "Yes"
    click_button "Continue"

    # further-education-provision-search
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    # select-provision
    choose eligible_college.name
    click_button "Continue"

    # contract-type
    choose "Permanent contract"
    click_button "Continue"

    # teaching-hours-per-week
    choose "12 hours or more per week"
    click_button "Continue"

    # further-education-teaching-start-year
    choose "September 2023 to August 2024"
    click_button "Continue"

    # subjects-taught
    check "Building and construction"
    click_button "Continue"

    # building-construction-courses
    check "T Level in onsite construction"
    click_button "Continue"

    # hours-teaching-eligible-subjects
    choose "Yes"
    click_button "Continue"

    # half-teaching-hours
    choose "Yes"
    click_button "Continue"

    # teaching-qualification
    choose "Yes"
    click_button "Continue"

    # poor-performance
    within all(".govuk-fieldset")[0] do
      choose("No")
    end

    within all(".govuk-fieldset")[1] do
      choose("No")
    end

    click_button "Continue"

    # check-your-answers-part-one
    click_button "Continue"

    # eligible
    click_button "Apply now"

    # sign-in 1
    mock_one_login_auth(uid: "12345")
    click_button "Continue"

    # sign-in 2
    mock_one_login_idv(uid: "12345")
    click_button "Continue"

    # sign-in 3
    click_button "Continue"

    # ineligible
    expect(page).to have_content(
      "You've already submitted a claim in this claim window"
    )

    expect(page).to have_content(previous_claim.reference)

    expect(current_url).to end_with(
      "/ineligible?ineligible_reason=claim_already_submitted_this_policy_year"
    )
  end

  def and_ineligible_college_exists
    ineligible_college
  end

  def and_eligible_college_exists
    eligible_college
  end

  def and_closed_eligible_college_exists
    closed_eligible_college
  end
end
