require "rails_helper"

RSpec.feature "Trainee Teacher - Early Career Payments - journey" do
  context "when Claim AcademicYear is 2022/2023" do
    let(:ecp_only_school) { create(:school, :early_career_payments_eligible) }

    before { create(:journey_configuration, :additional_payments) }

    scenario "ECP-only school with trainee teacher" do
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

      choose_school ecp_only_school

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

      choose "No, I’m a trainee teacher"
      click_on "Continue"

      expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
    end
  end
end
