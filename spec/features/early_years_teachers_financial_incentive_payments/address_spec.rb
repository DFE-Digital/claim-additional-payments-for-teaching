require "rails_helper"

RSpec.feature "EYTFI address", feature_flag: [:eytfi_journey], slow: true do
  include_examples "stub_teacher_auth"

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

  it_behaves_like(
    "an address journey",
    change_address_link: "Change home address",
    check_answers_heading: "Confirm your details and complete your claim"
  )

  def complete_journey_upto_postcode_search
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(
      Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
    )

    click_link "Start now"

    fill_in "claim[nursery_search_query]", with: "Springfield nursery"
    click_button "Continue"

    choose "Springfield nursery"
    click_button "Continue"

    choose "Yes"
    click_button "Continue"

    check "I spend at least half"
    check "I’m not currently subject"
    click_button "Confirm and continue"

    click_button "Continue"

    perform_enqueued_jobs do
      click_button "Continue"
    end

    choose "Yes"
    click_button "Continue"

    upload_employment_proof

    click_button "Continue"

    expect(page).to have_text "What is your home address?"
  end

  def complete_journey_from_address_to_check_answers
    choose "I don’t know"
    click_button "Continue"

    fill_in "Enter your National Insurance number", with: "AB123456C"
    click_button "Continue"

    fill_in "Name on your account", with: "John Doe"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "12345678"
    click_button "Continue"

    expect(page).to have_text "Confirm your details and complete your claim"
  end
end
