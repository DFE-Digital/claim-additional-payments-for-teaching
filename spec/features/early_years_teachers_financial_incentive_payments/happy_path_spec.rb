require "rails_helper"

RSpec.feature "EYTFI journey", feature_flag: [:eytfi_journey] do
  let(:mock_teacher) do
    instance_double(
      "Dqt::Teacher",
      has_eligible_eytfi_qualification?: true
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

    allow(Dqt::Client).to receive(:new).and_return(mock_client)
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
    perform_enqueued_jobs do
      click_button "Continue"
    end

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
end
