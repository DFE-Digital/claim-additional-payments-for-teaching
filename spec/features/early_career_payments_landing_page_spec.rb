require "rails_helper"

RSpec.feature "Landing page - Early Career Payments - journey" do
  let!(:school) { create(:school, :early_career_payments_eligible) }

  before { create(:policy_configuration, :additional_payments) }

  scenario "navigate to first page in ECP journey" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start now"

    # - Sign in or continue page
    expect(page).to have_text("You can use a DfE Identity account with this service")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school school

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))
  end
end
