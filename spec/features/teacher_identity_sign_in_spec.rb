require "rails_helper"

RSpec.feature "Teacher Identity Sign in" do
  include EarlyCareerPaymentsHelper

  def set_mock_auth(trn)
    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(
      "extra" => {
        "raw_info" => {
          "trn" => trn
        }
      }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:default]
  end

  # create a school eligible for ECP and LUP so can walk the whole journey
  let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }
  let(:current_academic_year) { policy_configuration.current_academic_year }

  let(:itt_year) { current_academic_year - 3 }

  scenario "Teacher makes claim for 'Early-Career Payments' claim with trn present" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    set_mock_auth("12345678")
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    # - Which school do you teach at
    click_on "Sign in with teacher identity"
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("questions.current_school"))

    # - Should have Query params TRN
    expect(page.current_url).to include("trn=")
  end

  scenario "Teacher makes claim for 'Early-Career Payments' claim with no trn" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    set_mock_auth(nil)
    expect(page).to have_link("Claim additional payments for teaching", href: "/additional-payments/landing-page")
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    # - Which school do you teach at
    click_on "Sign in with teacher identity"
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(page.title).to have_text(I18n.t("questions.current_school"))

    # - Should not have Query params TRN
    expect(page.current_url).not_to include("trn=")
  end
end
