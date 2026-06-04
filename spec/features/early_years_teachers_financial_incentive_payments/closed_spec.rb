require "rails_helper"

RSpec.feature "EYTFI journey" do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )
  end

  scenario "when feature toggled off" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    expect(page).to have_text "Page not found"
    expect(page.status_code).to eql(404)
  end

  scenario "when journey config closed", feature_flag: [:eytfi_journey] do
    Journeys::Configuration.last.update open_for_submissions: false

    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    expect(page).not_to have_text "Start now"

    visit "/early-years-teachers-recognition-payments/nursery-search"
    expect(page).to have_text "Sorry, the service is unavailable"
  end
end
