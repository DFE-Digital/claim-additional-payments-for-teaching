require "rails_helper"

RSpec.feature "Teacher Identity Sign in" do
  include OmniauthMockHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { policy_configuration.current_academic_year }

  let(:itt_year) { current_academic_year - 3 }

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id and selects yes to details confirm" do
    visit landing_page_path(EarlyCareerPayments.routing_name)

    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("You can use a DfE Identity account with this service")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("questions.current_school"))
  end

  scenario "Teacher makes claim for 'Early-Career Payments' by logging in with teacher_id and selects no to details confirm" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    set_mock_auth("12345678")
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    expect(page).to have_text("You can use a DfE Identity account with this service")
    click_on "Sign in with teacher identity"

    # - Teacher details page
    expect(page).to have_text("Check and confirm your details")
    expect(page).to have_text("Are these details correct?")

    choose "No"
    click_on "Continue"

    # - You cannot user from DFE identity account page
    expect(page).to have_text("You cannot use your DfE Identify account with this service")
    click_on "Continue"

    # - Landing page
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
  end
end
