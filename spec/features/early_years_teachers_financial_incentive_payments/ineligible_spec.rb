require "rails_helper"

RSpec.feature "EYTFI journey ineligible paths", feature_flag: [:eytfi_journey] do
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

  scenario "claimant states they do not have relevant qualification" do
    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "No"
    click_button "Continue"

    expect(page).to have_text "You are not eligible for this payment"
  end
end
