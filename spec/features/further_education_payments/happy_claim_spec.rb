require "rails_helper"

RSpec.feature "Further education payments" do
  scenario "happy path claim" do
    when_further_education_payments_journey_configuration_exists

    visit landing_page_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
    expect(page).to have_link("Start now")
    click_link "Start now"

    expect(page).to have_content("Are you a member of staff with teaching responsibilities?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content("FE provision search goes here")
    click_button "Continue"

    expect(page).to have_content("FE contract type goes here")
    click_button "Continue"

    expect(page).to have_content("FE teaching hours per week goes here")
    click_button "Continue"

    expect(page).to have_content("FE academic year in further education goes here")
    click_button "Continue"

    expect(page).to have_content("FE subject areas goes here")
    click_button "Continue"

    expect(page).to have_content("FE building and construction courses goes here")
    click_button "Continue"

    expect(page).to have_content("FE teaching courses goes here")
    click_button "Continue"

    expect(page).to have_content("FE half teaching hours goes here")
    click_button "Continue"

    expect(page).to have_content("FE qualification goes here")
    click_button "Continue"

    expect(page).to have_content("FE poor performance goes here")
    click_button "Continue"

    expect(page).to have_content("FE check your answers goes here")
  end

  def when_further_education_payments_journey_configuration_exists
    create(:journey_configuration, :further_education_payments)
  end
end
