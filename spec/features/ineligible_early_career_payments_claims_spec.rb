require "rails_helper"

RSpec.feature "Ineligible Teacher Early Career Payments claims" do
  scenario "NQT not in Academic Year after ITT" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # [PAGE 00] - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # [PAGE 01] - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  scenario "When suject to disciplinary action" do
    start_early_career_payments_claim

    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # [PAGE 08] - Are you currently subject to dsiciplinary action
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "Yes"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  scenario "supply teacher doesn't have a contract for a whole term" do
    start_early_career_payments_claim

    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    # [PAGE 05] - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  # Employed as Supply Teacher by Private Agency
  scenario "Supply Teacher employed directly by Private Agency" do
    start_early_career_payments_claim

    # [PAGE 04] - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    # [PAGE 05] - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    # [PAGE 06] - Are you employed directly by your school
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_directly"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible"))
    expect(page).to have_link(href: EarlyCareerPayments.eligibility_page_url)
    expect(page).to have_text("Based on the answers you have provided you are not eligible #{I18n.t("early_career_payments.claim_description")}")
  end

  # Additional sad paths
  # TODO [PAGE 17] - This school is not eligible (sad path)
  # TODO [PAGE 19] - You will be eligible for an early career payment in 2022
end
