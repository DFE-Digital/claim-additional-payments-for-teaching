require "rails_helper"

RSpec.feature "EYTFI journey", feature_flag: [:eytfi_journey] do
  before do
    create(
      :journey_configuration,
      :early_years_teachers_financial_incentive_payments
    )

    OmniAuth.config.mock_auth[:teacher] = OmniAuth::AuthHash.new({
      provider: "teacher",
      extra: {
        raw_info: {
          sub: "urn:fdc:gov.uk:2022:#{SecureRandom.base64(30)}",
          trn: "1234567",
          email: "john.doe@example.com",
          verified_name: ["John", "Doe"],
          verified_date_of_birth: "1970-12-13"
        }
      }
    })
  end

  scenario "happy path" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    click_button "Continue"

    expect(page).to have_text "You are eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    click_button "Continue"

    expect(page).to have_text "TRN found"
  end
end
