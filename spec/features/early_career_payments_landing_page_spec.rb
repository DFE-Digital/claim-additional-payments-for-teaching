require "rails_helper"

RSpec.feature "Landing page - Early Career Payments - journey" do
  context "when Claim AcademicYear is 2021" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2021))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "navigate to first page in ECP journey when academic year is 2021" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      expect(page).to have_text("Who is eligible in 2021/22?")
      expect(page).to have_text("Who can apply in the future?")
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading.2021"))
    end
  end

  context "when Claim AcademicYear is 2022" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "navigate to first page in ECP journey when academic year is 2022" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      expect(page).to have_text("Who is eligible now?")
      expect(page).to have_text("Who can apply in autumn 2023?")
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading.default", started_or_completed: :started))
    end
  end

  context "when Claim AcademicYear is 2023" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2023))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "navigate to first page in ECP journey when academic year is 2023" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      expect(page).to have_text("Who is eligible now?")
      expect(page).to have_text("Who can apply in autumn 2024?")
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text("Have you completed your first year as a newly qualified teacher or early-career teacher?")
    end
  end

  context "when Claim AcademicYear is 2024" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2024))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    scenario "navigate to first page in ECP journey when academic year is 2024" do
      visit landing_page_path(EarlyCareerPayments.routing_name)
      expect(page).to have_link(href: "mailto:#{EarlyCareerPayments.feedback_email}")

      # - Landing (start)
      expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
      expect(page).to have_text("Who is eligible now?")
      expect(page).to have_text("This is the final year eligible teachers can apply for an early-career payment")
      click_on "Start Now"

      # - NQT in Academic Year after ITT
      expect(page).to have_text("Have you completed your first year as a newly qualified teacher or early-career teacher?")
    end
  end
end
