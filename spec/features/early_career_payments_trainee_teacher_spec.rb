require "rails_helper"

RSpec.feature "Trainee Teacher - Early Career Payments - journey" do
  context "when Claim AcademicYear is 2022/2023" do
    # TODO remove fixture dependence
    let(:ecp_only_school) { schools(:penistone_grammar_school) }

    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "ECP-only school with trainee teacher" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      click_on "Start now"

      # - Which school do you teach at
      expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

      choose_school ecp_only_school

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

      choose "No, I’m a trainee teacher"
      click_on "Continue"

      expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    end
  end
end
