require "rails_helper"

RSpec.feature "Ineligible Levelling up premium payments claims" do
  let(:eligibility) { LevellingUpPremiumPayments::Eligibility.order(:created_at).last }

  scenario "When the school selected is LUP ineligible" do
    start_levelling_up_premium_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(eligibility.ineligible?).to be false
    choose_school schools(:penistone_grammar_school)
    click_on "Continue"
    expect(eligibility.reload.ineligible?).to be true

    expect(page).not_to have_text("The school you have selected is not eligible")
  end

  scenario "When the school selected is both ECP and LUP ineligible" do
    start_levelling_up_premium_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    expect(eligibility.ineligible?).to be false
    choose_school schools(:bradford_grammar_school)
    click_on "Continue"
    expect(eligibility.reload.ineligible?).to be true

    expect(page).to have_text("The school you have selected is not eligible")
  end

  scenario "When subject 'none of the above' and user does not have an eligible degree" do
    start_levelling_up_premium_payments_claim

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))
    choose_school schools(:hampstead_school)
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text("your first year as an early career teacher?")

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"

    click_on "Continue"

    # - In which academic year did you complete your undergraduate ITT?
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.undergraduate_itt"))

    choose "2018 to 2019"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: "undergraduate initial teacher training (ITT)"))
    choose "None of the above"
    click_on "Continue"

    # Do you have an undergraduate or postgraduate degree in an eligible subject?
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))
    choose "No"

    expect(eligibility.ineligible?).to be false
    click_on "Continue"
    expect(eligibility.reload.ineligible?).to be true

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_link(href: "#{EarlyCareerPayments.eligibility_page_url}#eligibility-criteria")
  end
end
