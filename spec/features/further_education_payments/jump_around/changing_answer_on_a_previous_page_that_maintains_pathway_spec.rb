require "rails_helper"

RSpec.feature "Further education payments" do
  include ActionView::Helpers::NumberHelper

  let(:school) { create(:school, :fe_eligible) }
  let(:college) { school }
  let(:expected_award_amount) { college.eligible_fe_provider.max_award_amount }

  # user reaches an ineligible state
  # hits back button more than once
  # changes an answer that does not change pathway
  # ie they are still ineligible
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

  def and_college_exists
    school
  end
end
