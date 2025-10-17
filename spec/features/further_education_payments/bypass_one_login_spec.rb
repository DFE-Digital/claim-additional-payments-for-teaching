require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:college) { create(:school, :further_education, :fe_eligible) }
  let(:expected_award_amount) { college.eligible_fe_provider.max_award_amount }

  scenario "cant bypass OL" do
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
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
    fill_in "claim[provision_search]", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have directly with #{college.name}?")
    choose("Permanent")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?")
    choose("More than 12 hours per week")
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    check("Chemistry")
    check("Computing, including digital and ICT")
    check("Early years")
    check("Engineering and manufacturing, including transport engineering and electronics")
    check("Maths")
    check("Physics")
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in building services engineering for construction"
    click_button "Continue"

    expect(page).to have_content("Which chemistry courses do you teach?")
    check "GCSE chemistry"
    click_button "Continue"

    expect(page).to have_content("Which computing courses do you teach?")
    check "T Level in digital support services"
    click_button "Continue"

    expect(page).to have_content("Which early years courses do you teach?")
    check "T Level in education and early years (early years educator)"
    click_button "Continue"

    expect(page).to have_content("Which engineering and manufacturing courses do you teach?")
    check "T Level in design and development for engineering and manufacturing"
    click_button "Continue"

    expect(page).to have_content("Which maths courses do you teach?")

    check("claim-maths-courses-approved-level-321-maths-field")
    click_button "Continue"

    expect(page).to have_content("Which physics courses do you teach?")
    check "A or AS level physics"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    expect(page).to have_content("T Level in building services engineering for construction")
    expect(page).to have_content("GCSE chemistry")
    expect(page).to have_content("T Level in digital support services")
    expect(page).to have_content("T Level in education and early years (early years educator)")
    expect(page).to have_content("T Level in design and development for engineering and manufacturing")
    expect(page).to have_content("Qualifications approved for funding at level 3 and below in the")
    expect(page).to have_content("A or AS level physics")
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

    expect(page).to have_content("Sign in with GOV.UK One Login")

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, "information-provided")

    expect(page).to have_content("Sign in with GOV.UK One Login")
  end

  scenario "cant bypass OL with just auth" do
    when_student_loan_data_exists
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
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
    fill_in "claim[provision_search]", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose college.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have directly with #{college.name}?")
    choose("Permanent")
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?")
    choose("More than 12 hours per week")
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check("Building and construction")
    check("Chemistry")
    check("Computing, including digital and ICT")
    check("Early years")
    check("Engineering and manufacturing, including transport engineering and electronics")
    check("Maths")
    check("Physics")
    click_button "Continue"

    expect(page).to have_content("Which building and construction courses do you teach?")
    check "T Level in building services engineering for construction"
    click_button "Continue"

    expect(page).to have_content("Which chemistry courses do you teach?")
    check "GCSE chemistry"
    click_button "Continue"

    expect(page).to have_content("Which computing courses do you teach?")
    check "T Level in digital support services"
    click_button "Continue"

    expect(page).to have_content("Which early years courses do you teach?")
    check "T Level in education and early years (early years educator)"
    click_button "Continue"

    expect(page).to have_content("Which engineering and manufacturing courses do you teach?")
    check "T Level in design and development for engineering and manufacturing"
    click_button "Continue"

    expect(page).to have_content("Which maths courses do you teach?")

    check("claim-maths-courses-approved-level-321-maths-field")
    click_button "Continue"

    expect(page).to have_content("Which physics courses do you teach?")
    check "A or AS level physics"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    expect(page).to have_content("T Level in building services engineering for construction")
    expect(page).to have_content("GCSE chemistry")
    expect(page).to have_content("T Level in digital support services")
    expect(page).to have_content("T Level in education and early years (early years educator)")
    expect(page).to have_content("T Level in design and development for engineering and manufacturing")
    expect(page).to have_content("Qualifications approved for funding at level 3 and below in the")
    expect(page).to have_content("A or AS level physics")
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

    expect(page).to have_content("Sign in with GOV.UK One Login")

    mock_one_login_auth

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, "information-provided")
    expect(page).to have_content("Sign in with GOV.UK One Login")
    click_button "Continue"

    expect(page).to have_content("You’ve successfully signed in to GOV.UK One Login")

    mock_one_login_idv

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, "information-provided")
    expect(page).to have_content("Identity verification")
    click_button "Continue"

    visit claim_path(Journeys::FurtherEducationPayments::ROUTING_NAME, "information-provided")
    expect(page).to have_content("How we will use your information")
  end

  def and_college_exists
    college
  end
end
