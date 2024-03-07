require "rails_helper"

RSpec.feature "Teacher Identity Sign in" do
  include OmniauthMockHelper

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { journey_configuration.current_academic_year }
  let(:trn) { 1234567 }
  let(:date_of_birth) { "1981-01-01" }
  let(:nino) { "AB123123A" }

  let(:itt_year) { current_academic_year - 3 }

  before do
    set_mock_auth(trn, {date_of_birth:, nino:})
    stub_dqt_empty_response(trn:, params: {birthdate: date_of_birth, nino:})
  end

  scenario "Teacher makes claim for 'Early-Career Payments' claim and select continue without signing in" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{I18n.t("additional_payments.feedback_email")}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
  end

  scenario "Teacher makes claim for 'Early-Career Payments' claim and select Continue with DfE Identity" do
    visit landing_page_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{I18n.t("additional_payments.feedback_email")}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue with DfE Identity"

    # - Teacher details page
    expect(page).to have_text(I18n.t("questions.check_and_confirm_details"))
    expect(page).to have_text(I18n.t("questions.details_correct"))

    choose "Yes"
    click_on "Continue"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
  end
end
