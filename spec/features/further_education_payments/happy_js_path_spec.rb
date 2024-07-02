require "rails_helper"

RSpec.feature "Further education payments", js: true, flaky: true do
  let(:college) { create(:school, :further_education) }

  scenario "happy js path" do
    when_further_education_payments_journey_configuration_exists
    and_college_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("Which FE provider are you employed by?")
    fill_in "Which FE provider are you employed by?", with: college.name
    within("#claim-provision-search-field__listbox") do
      find("li", text: college.name).click
    end
    click_button "Continue"

    expect(page).to have_content("Select the college you teach at")
    expect(page).to have_selector "input[type=radio][checked=checked][value='#{college.id}']", visible: false
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

    expect(page).to have_content("FE half teaching hours goes here")
    click_button "Continue"

    expect(page).to have_content("Do you have a teaching qualification?")
    choose("Yes")
    click_button "Continue"

    expect(page).to have_content("FE poor performance goes here")
    click_button "Continue"

    expect(page).to have_content("FE check your answers goes here")
  end

  def when_further_education_payments_journey_configuration_exists
    create(:journey_configuration, :further_education_payments)
  end

  def and_college_exists
    college
  end
end
