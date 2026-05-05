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
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

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

    expect(page).to have_text "You are eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"
    click_button "Continue"

    expect(page).to have_text "You hold an eligible qualification"
    click_button "Continue"

    expect(page).to have_text "Confirm you are eligible"
    click_button "Continue"

    expect(page).to have_text "Before you accept the claim"
    click_button "Continue"

    expect(page).to have_text "How we’ll use your information"
  end

  scenario "using nursery auto complete - js", js: true do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"

    find_field("claim[nursery_search_query]").send_keys("Spr")
    find("li", text: "Springfield nursery").click

    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
  end

  scenario "not using auto complete - js", js: true do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"

    find_field("claim[nursery_search_query]").send_keys("Spr")
    find("h1").click # click somewhere else to disimiss the autocomplete dropdown
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
  end

  scenario "ineligible nursery chosen" do
    create(
      :eligible_eytfi_provider,
      name: "Shelbyvile nursery",
      eligible: false
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Shelbyvile nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Shelbyvile nursery"
    click_button "Continue"

    expect(page).to have_text("You are not eligible for this payment")

    expect(page).to have_text(
      "To be eligible for the early years teacher recognition payment you must be a qualified early years teacher in an eligible local authority area."
    )
  end

  scenario "ineligible qualification option" do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    expect(page).to have_text "Which nursery do you teach in?"
    find_field("claim[nursery_search_query]").set("Springfield nursery")
    click_button "Continue"

    expect(page).to have_text "Which nursery do you teach in?"
    choose "Springfield nursery"
    click_button "Continue"

    expect(page).to have_text "Do you hold one of these teaching qualifications?"
    choose "No"
    click_button "Continue"

    expect(page).to have_text("You are not eligible for this payment")

    expect(page).to have_text(
      "To be eligible for the early years teacher recognition payment you must be a qualified early years teacher in an eligible local authority area."
    )
  end
end
