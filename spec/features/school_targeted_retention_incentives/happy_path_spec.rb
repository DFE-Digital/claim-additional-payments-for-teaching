require "rails_helper"

RSpec.describe "new STRI journey", feature_flag: [:new_stri] do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  let(:school) do
    create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )
  end

  scenario "happy path" do
    visit landing_page_path(Journeys::SchoolTargetedRetentionIncentivePayments.routing_name)
    expect(page).to have_text "Use this service to find out if you can get an early career teacher payment."
    click_link "Start now"

    expect(page).to have_text "Enter the school name or postcode using at least 3 characters"
    fill_in "What school do you teach at?", with: school.name
    click_button "Continue"

    expect(page).to have_text "Select your school from the search results."
    choose school.name
    click_button "Continue"

    expect(page).to have_text "Do you spend at least half of your contracted"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "hello"
  end
end
