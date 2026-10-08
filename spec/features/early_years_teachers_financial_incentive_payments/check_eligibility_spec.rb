require "rails_helper"

RSpec.feature "EYTFI check eligibility page", feature_flag: [:eytfi_journey] do
  before do
    create(:journey_configuration, :early_years_teachers_financial_incentive_payments)
    create(:eligible_eytfi_provider, name: "Springfield nursery")

    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    choose "Springfield nursery"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
  end

  scenario "yes proceeds to the next page" do
    choose "Yes"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
  end

  scenario "no redirects to ineligible" do
    choose "No"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re not eligible for this payment"
  end
end
