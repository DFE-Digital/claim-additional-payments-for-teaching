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

    expect(page).to have_text("You are not eligible for this payment")

    expect(page).to have_text(
      "To be eligible for the early years teacher recognition payment you must be a qualified early years teacher in an eligible local authority area."
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
    let(:mock_teacher) do
      instance_double(
        "Dqt::Teacher",
        has_eligible_eytfi_qualification?: false
      )
    end

    let(:mock_teacher_resource) do
      instance_double(
        "Dqt::TeacherResource",
        find: mock_teacher
      )
    end

    let(:mock_client) do
      instance_double(
        "Dqt::Client",
        teacher: mock_teacher_resource
      )
    end

    before do
      allow(Dqt::Client).to receive(:new).and_return(mock_client)
    end

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
end
