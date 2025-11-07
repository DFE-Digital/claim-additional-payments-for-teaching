require "rails_helper"

RSpec.feature "Combined journey with Teacher ID email check" do
  include OmniauthMockHelper
  include ClaimsControllerHelper

  # create a school eligible for ECP and Targeted Retention Incentive so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments) }
  let(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }
  let(:email) { "kelsie.oberbrunner@example.com" }
  let(:new_email) { "new.email@example" }

  before do
    school
    freeze_time
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
    mock_claims_controller_address_data
  end

  after do
    set_mock_auth(nil)
    travel_back
  end

  scenario "Selects email address to be contacted" do
    # - Selects suggested email address
    navigate_to_check_email_page(school:)

    # - select-email page

    # - Select the suggested email address
    choose(email)
    click_on "Continue"

    expect(page).to have_text("Which mobile number should we use to contact you?")

    session = Journeys::TargetedRetentionIncentivePayments::Session.order(created_at: :desc).last

    expect(session.answers.email_address).to eq("kelsie.oberbrunner@example.com")
    expect(session.answers.email_address_check).to eq(true)
    expect(session.answers.email_verified).to eq(true)

    # - Select a different email address
    click_on "Back"

    # - select-email page

    # - Select A different email address
    choose("A different email address")
    click_on "Continue"

    expect(page).to have_text("We recommend you use a non-work email address in case your circumstances change while we process your payment.")

    session.reload

    expect(session.answers.email_address).to eq(nil)
    expect(session.answers.email_address_check).to eq(false)
    expect(session.answers.email_verified).to eq(nil)
  end

  def navigate_to_check_email_page(school:)
    visit landing_page_path(Journeys::TargetedRetentionIncentivePayments.routing_name)

    # - Landing (start)
    expect(page).to have_text("Find out if you are eligible for a targeted retention incentive payment")
    click_on "Start now"

    # - Check eligibility intro
    expect(page).to have_text("Check you’re eligible for a targeted retention incentive payment")
    click_on "Start eligibility check"

    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text("Check and confirm your personal details")
    expect(page).to have_text("Are these details correct?")

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text("Which school do you teach at?")
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text("Are you currently teaching as a qualified teacher?")

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text("Are you currently employed as a supply teacher?")

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text("Are you subject to any formal performance measures as a result of continuous poor teaching standards?")
    expect(page).to have_text("Are you currently subject to disciplinary action?")

    within all(".govuk-fieldset")[0] do
      choose("No")
    end
    within all(".govuk-fieldset")[1] do
      choose("No")
    end
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text("Which route into teaching did you take?")

    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(page).to have_text("In which academic year did you complete your undergraduate initial teacher training (ITT)?")
    choose "2020 to 2021"
    click_on "Continue"

    # User should be redirected to the next question which was previously answered but wiped by the attribute dependency
    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text("Do you spend at least half of your contracted hours teaching eligible subjects?")
    choose "Yes"
    click_on "Continue"

    # - Check your answers for eligibility
    expect(page).to have_text("Check your answers")
    click_on("Continue")

    expect(page).to have_text("You’re eligible for a targeted retention incentive payment")
    click_on("Apply now")

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details - skipped as all details from TID are valid
    expect(page).not_to have_text("Personal details")

    # - What is your home address
    expect(page).to have_text("What is your home address?")

    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    # - Select your home address
    expect(page).to have_text("What is your home address?")

    choose "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_on "Continue"
  end
end
