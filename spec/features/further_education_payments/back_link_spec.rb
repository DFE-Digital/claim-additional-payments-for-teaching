require "rails_helper"

RSpec.feature "Further education back link" do
  let(:school) { create(:school, :fe_eligible) }

  scenario "are correct" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: school.name
    click_button "Continue"

    expect(page).to have_content("Select where you are employed")
    choose school.name
    click_button "Continue"

    expect(page).to have_content("What type of contract do you have")
    choose "Permanent contract"
    click_button "Continue"

    expect(page).to have_content("On average, how many hours per week are you timetabled to teach")
    choose "12 hours or more per week"
    click_button "Continue"

    expect(page).to have_content("Which academic year did you start teaching in further education (FE) in England?")
    choose "September 2024 to August 2025"
    click_button "Continue"

    expect(page).to have_content("Which subject areas do you teach?")
    check "Chemistry"
    click_button "Continue"

    expect(page).to have_content("Which chemistry courses do you teach?")
    check "GCSE chemistry"
    click_button "Continue"

    expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching these eligible courses?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Are at least half of your timetabled teaching hours spent teaching")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Tell us if you are currently under any performance measures or disciplinary action")
    choose "claim-subject-to-formal-performance-action-true-field"
    choose "claim-subject-to-disciplinary-action-true-field"
    click_button "Continue"

    expect(page).to have_content("You are not eligible")
    click_link "Back"

    expect(page).to have_content("Tell us if you are currently under any performance measures or disciplinary action")
  end
end
