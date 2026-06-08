require "rails_helper"

RSpec.describe "EYTFIP with teacher auth failure", feature_flag: [:eytfi_journey] do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )
  end

  scenario "when failure is csrf_detected" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    expect(page).to have_text "Claim an early years teacher recognition payment"
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Springfield nursery"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_text "Check if you’re eligible"
    check "I spend at least half"
    check "I’m not currently subject"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"

    allow(Sentry).to receive(:capture_message)

    visit "/early-years-teachers-financial-incentive-payments/auth/failure?message=csrf_detected&strategy=teacher"
    expect(page).to have_text("Sorry, there is a problem with the service")
    expect(page).to have_text("Try again later")
    click_link "Try again"

    expect(Sentry).to have_received(:capture_message)

    expect(page).to have_text "You’re eligible to apply"
  end
end
