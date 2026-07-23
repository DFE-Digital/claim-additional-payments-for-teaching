require "rails_helper"

RSpec.feature "Further education payments ineligible paths" do
  let(:ineligible_college) { create(:school, :further_education) }
  let(:eligible_college) { create(:school, :further_education, :fe_eligible) }
  let(:closed_eligible_college) { create(:school, :further_education, :fe_eligible, :closed) }
  let(:current_academic_year) { AcademicYear.current }

  scenario "when not a recent FE teacher" do
    when_further_education_payments_journey_configuration_exists
    and_eligible_college_exists

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
    fill_in "claim[provision_search]", with: eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose eligible_college.name
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start your further education (FE) teaching career in England?")
    choose("Before September #{current_academic_year.start_year - 4}")
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be in the first 5 years of")
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
