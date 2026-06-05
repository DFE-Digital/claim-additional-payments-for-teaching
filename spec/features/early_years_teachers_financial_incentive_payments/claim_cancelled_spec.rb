require "rails_helper"

RSpec.describe "EYTFI - Claim cancelled", feature_flag: [:eytfi_journey] do
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

  it "allows the claimant to cancel their claim" do
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

    expect(page).to have_text("Check that you are eligible")
    check "I spend at least half"
    check "I’m not currently subject"
    click_button "Confirm and continue"

    expect(page).to have_text "You’re eligible to apply"
    click_button "Continue"

    expect(page).to have_text "Sign in with GOV.UK One Login"

    perform_enqueued_jobs do
      click_button "Continue"
    end

    expect(page).to have_text "You may be eligible for a recognition payment"
    choose "No"
    click_button "Continue"

    expect(page).to have_content "Your claim has been cancelled"

    click_on "Start a new claim"

    click_on "Start now"

    # As we've cleared the session expect not to see the claim in progress
    # warning
    expect(page).not_to have_content(
      "You have already started an eligibility check"
    )
  end
end
