require "rails_helper"

RSpec.describe "Journey session expiry" do
  let(:college) { create(:school, :further_education, :fe_eligible) }

  before do
    create(
      :journey_configuration,
      :further_education_payments
    )
  end

  scenario "after session expiry starts new session" do
    when_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_text "Do you have a GOV.UK One Login account?"
    choose "Yes"
    click_button "Continue"

    sign_in_with_one_login

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

    expect(page).to have_text("Which academic year did you start teaching in further education in England?")
    choose("September 2023 to August 2024")
    click_button "Continue"

    expect(page).to have_text("Do you have a teaching qualification?")
    last_path = current_path

    travel(2.days)
    ExpireJourneySessionsJob.perform_now

    visit last_path
    expect(page).not_to have_text("Do you have a teaching qualification?")
    expect(page).to have_link "Start now"
  end

  def when_college_exists
    college
  end
end
