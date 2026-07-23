require "rails_helper"

RSpec.feature "Further education payments ineligible paths" do
  let(:ineligible_college) { create(:school, :further_education) }
  let(:eligible_college) { create(:school, :further_education, :fe_eligible) }
  let(:closed_eligible_college) { create(:school, :further_education, :fe_eligible, :closed) }
  let(:current_academic_year) { AcademicYear.current }

  scenario "when the claimant has already submitted a claim" do
    create(:journey_configuration, :further_education_payments)

    previous_claim = create(
      :claim,
      :further_education,
      onelogin_uid: "12345"
    )

    visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)

    click_link "Start now"

    expect(page).to have_text("Do you have a GOV.UK One Login account")
    choose "No"
    click_button "Continue"

    expect(page).to have_text("Did you apply for a targeted retention incentive payment in further education")
    choose "No"
    click_button "Continue"

    # check-eligibility-intro
    expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
    click_button "Start eligibility check"

    # teaching-responsibilities
    choose "Yes"
    click_button "Continue"

    # further-education-provision-search
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    # select-provision
    choose eligible_college.name
    click_button "Continue"

    # further-education-teaching-start-year
    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    # teaching-qualification
    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    # contract-type
    choose "Permanent"
    click_button "Continue"

    # teaching-hours-per-week
    choose "12 or more hours per week, but fewer than 20"
    click_button "Continue"

    # half-teaching-hours
    choose "Yes"
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

    # sign-in
    mock_one_login_auth(uid: "12345")
    click_button "Continue"

    expect(page).to have_content(
      "You’ve successfully signed in to GOV.UK One Login"
    )
    click_button "Continue"

    # ineligible
    expect(page).to have_content(
      "You’ve already submitted a claim in this claim window"
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
