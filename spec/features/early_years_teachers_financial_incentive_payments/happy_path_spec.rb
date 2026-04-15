require "rails_helper"

RSpec.feature "EYTFI journey", feature_flag: [:eytfi_journey] do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )
  end

  scenario "happy path" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    expect(page).to have_text "sign in page goes here"
  end
end
