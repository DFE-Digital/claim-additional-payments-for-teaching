require "rails_helper"

RSpec.feature "Landing page - Early Career Payments - journey" do
  let!(:school) { create(:school, :early_career_payments_eligible) }

  before { create(:journey_configuration, :additional_payments) }

  scenario "navigate to first page in ECP journey" do
    visit landing_page_path(Policies::EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: "mailto:#{I18n.t("additional_payments.feedback_email")}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("additional_payments.landing_page"))
    click_on "Start now"

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))

    choose_school school

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))
  end
end
