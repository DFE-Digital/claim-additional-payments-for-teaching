require "rails_helper"

RSpec.feature "Further education payments ineligible paths" do
  let(:ineligible_college) { create(:school, :further_education) }
  let(:eligible_college) { create(:school, :further_education, :fe_eligible) }
  let(:closed_eligible_college) { create(:school, :further_education, :fe_eligible, :closed) }
  let(:current_academic_year) { AcademicYear.current }

  scenario "when no teaching responsibilities" do
    when_further_education_payments_journey_configuration_exists

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
    choose "No"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    expect(page).to have_content("you must be employed as a member of staff with teaching responsibilities")
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
