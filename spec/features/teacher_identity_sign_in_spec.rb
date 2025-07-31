require "rails_helper"

RSpec.feature "Teacher Identity Sign in" do
  include OmniauthMockHelper

  # create a school eligible for ECP and Targeted Retention Incentive so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :targeted_retention_incentive_payments) }
  let(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }
  let(:current_academic_year) { journey_configuration.current_academic_year }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  let(:itt_year) { current_academic_year - 3 }

  before do
    school
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
  end

  scenario "Teacher makes claim" do
    # - Teacher makes claim without signing in
    visit landing_page_path("targeted-retention-incentive-payments")
    expect(page).to have_link("Claim a targeted retention incentive payment", href: "/targeted-retention-incentive-payments/landing-page")
    expect(page).to have_link(href: "mailto:additionalteachingpayment@digital.education.gov.uk")

    # - Landing (start)
    expect(page).to have_text("Find out if you are eligible for a targeted retention incentive payment")
    click_on "Start now"

    # - Check eligibility intro
    expect(page).to have_text("Check you're eligible for a targeted retention incentive payment")
    click_on "Start eligibility check"

    # - Sign in or continue page
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text("Which school do you teach at?")
    expect(page.title).to have_text("Which school do you teach at?")

    # - Teacher makes claim after signing in
    click_on "Back"
    
    # - Should be back at Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text("Check and confirm your personal details")
    expect(page).to have_text("Are these details correct?")

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text("Which school do you teach at?")
    expect(page.title).to have_text("Which school do you teach at?")
  end
end
