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

    expect(page).to have_text("The nursery you selected may not be eligible")

    expect(page).to have_text(
      "Based on our records, the nursery you selected is not currently eligible for the early years teacher recognition payment."
    )
  end

  scenario "claimant states they do not have relevant qualification" do
    create(
      :eligible_eytfi_provider,
      name: "Springfield nursery"
    )

    visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
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

    expect(page).to have_text "You are not eligible for this payment"
  end

  context do
    include_examples "stub_teacher_auth_with_ineligible_qualification"

    scenario "claimant does not have eligible qualification from TRS lookup" do
      create(
        :eligible_eytfi_provider,
        name: "Springfield nursery"
      )

      visit landing_page_path(Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name)
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
      perform_enqueued_jobs do
        click_button "Continue"
      end

      expect(page).to have_text "not eligible"
    end
  end

  context do
    include_examples "stub_teacher_auth"

    scenario "claimant rejects payment" do
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
      perform_enqueued_jobs do
        click_button "Continue"
      end

      journey_session = Journeys::EarlyYearsTeachersFinancialIncentivePayments::Session.last

      expect(journey_session.answers.teacher_auth_teacher_reference_number).to eql("1234567")
      expect(journey_session.answers.teacher_auth_email).to eql("john.doe@example.com")
      expect(journey_session.answers.teacher_auth_verified_name).to eql("John Doe")
      expect(journey_session.answers.teacher_auth_verified_date_of_birth).to eql(Date.new(1970, 12, 13))
      expect(journey_session.answers.teacher_auth_one_login_uid).to be_present
      expect(journey_session.answers.teacher_auth_completed_at).to be_within(1.minute).of(Time.zone.now)

      expect(journey_session.answers.trs_data).to be_present
      expect(journey_session.answers.trs_data_fetched_at).to be_within(1.minute).of(Time.zone.now)
      expect(journey_session.answers.has_eligible_qualification).to be_truthy

      expect(page).to have_text "You may be eligible for a recognition payment"
      choose "No"
      click_button "Continue"

      expect(page).to have_text "Claim cancelled"
      click_button "Start a new claim"

      expect(page).to have_text "Start now"
    end
  end
end
