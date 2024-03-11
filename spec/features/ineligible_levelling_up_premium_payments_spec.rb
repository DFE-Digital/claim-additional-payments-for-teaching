require "rails_helper"

RSpec.feature "Ineligible Levelling up premium payments claims" do
  let(:eligibility) { LevellingUpPremiumPayments::Eligibility.order(:created_at).last }

  before { create(:journey_configuration, :additional_payments) }

  scenario "When the school selected is LUP ineligible" do
    school = create(:school, :early_career_payments_eligible, :levelling_up_premium_payments_ineligible)
    start_levelling_up_premium_payments_claim

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))
    expect(eligibility.ineligible?).to be false
    choose_school school
    click_on "Continue"
    expect(eligibility.reload.ineligible?).to be true

    expect(page).not_to have_text("The school you have selected is not eligible")
  end

  scenario "When the school selected is both ECP and LUP ineligible" do
    school = create(:school, :early_career_payments_ineligible, :levelling_up_premium_payments_ineligible)
    start_levelling_up_premium_payments_claim

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))
    expect(eligibility.ineligible?).to be false
    choose_school school
    click_on "Continue"
    expect(eligibility.reload.ineligible?).to be true

    expect(page).to have_text("The school you have selected is not eligible")
  end

  scenario "When subject 'none of the above' and user does not have an eligible degree" do
    school = create(:school, :levelling_up_premium_payments_eligible)

    start_levelling_up_premium_payments_claim

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("additional_payments.questions.disciplinary_action"))

    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.questions.qualification.heading"))

    choose "Undergraduate initial teacher training (ITT)"

    click_on "Continue"

    # - In which academic year did you complete your undergraduate ITT?
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))

    choose "2018 to 2019"
    click_on "Continue"

    expect(page).to have_text("Which subject")
    choose "None of the above"
    click_on "Continue"

    # Do you have an undergraduate or postgraduate degree in an eligible subject?
    expect(page).to have_text(I18n.t("additional_payments.questions.eligible_degree_subject"))
    click_on "Continue"
    expect(page).to have_text("Select yes if you have a degree in an eligible subject")

    choose "No"

    expect(eligibility.ineligible?).to be false
    click_on "Continue"
    expect(eligibility.reload.ineligible?).to be true

    expect(page).to have_text(I18n.t("additional_payments.ineligible.heading"))
    expect(page).to have_css("div#lack_both_valid_itt_subject_and_degree")

    # Check we can go back and change the answer
    visit claim_path(LevellingUpPremiumPayments.routing_name, "eligible-degree-subject")
    expect(page).to have_current_path("/#{LevellingUpPremiumPayments.routing_name}/eligible-degree-subject")

    choose "Yes"
    click_on "Continue"

    expect(eligibility.reload).not_to be_ineligible

    expect(page).to have_current_path("/#{LevellingUpPremiumPayments.routing_name}/teaching-subject-now")
  end
end
