require "rails_helper"

RSpec.describe "new STRI journey", feature_flag: [:new_stri] do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  let(:school) { create(:school) }

  scenario "when ineligible school chosen" do
    visit landing_page_path(Journeys::SchoolTargetedRetentionIncentivePayments.routing_name)
    expect(page).to have_text "Use this service to find out if you can get an early career teacher payment."
    click_link "Start now"

    expect(page).to have_text "Enter the school name or postcode using at least 3 characters"
    fill_in "What school do you teach at?", with: school.name
    click_button "Continue"

    expect(page).to have_text "Select your school from the search results."
    choose school.name
    click_button "Continue"

    expect(page).to have_text "The school you have selected is not eligible"
  end
end
