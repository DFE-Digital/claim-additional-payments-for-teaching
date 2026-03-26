require "rails_helper"

RSpec.feature "Further education payments closed school with same details" do
  let(:college) { create(:school, :further_education, :closed, :fe_eligible, name: "Long island") }

  scenario "School selector includes closed information" do
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
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which further education provider directly employs you?")
    fill_in "claim[provision_search]", with: college.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    expect(page).to have_content("(closed)")
    choose college.name
    click_button "Continue"
  end
end
