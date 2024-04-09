require "rails_helper"

RSpec.feature "Combined claim journey dependent answers" do
  before { create(:journey_configuration, :additional_payments) }
  let!(:school) { create(:school, :combined_journey_eligibile_for_all) }

  scenario "Dependent answers reset" do
    visit new_claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)

    # - Sign in or continue page
    expect(page).to have_text("Use DfE Identity to sign in")
    click_on "Continue without signing in"

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("additional_payments.forms.current_school.questions.current_school_search"))
    choose_school school
    click_on "Continue"

    # - Have you started your first year as a newly qualified teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"))
    choose "Yes"
    click_on "Continue"

    # - Have you completed your induction as an early-career teacher?
    expect(page).to have_text(I18n.t("additional_payments.questions.induction_completed.heading"))
    choose "Yes"
    click_on "Continue"

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"))
    choose "No"
    click_on "Continue"

    # - Poor performance
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("additional_payments.forms.poor_performance.questions.disciplinary_action"))
    choose "claim_subject_to_formal_performance_action_false"
    choose "claim_subject_to_disciplinary_action_false"
    click_on "Continue"

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))
    choose "Postgraduate initial teacher training (ITT)"
    click_on "Continue"

    # - In which academic year did you complete your postgraduate ITT?
    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.postgraduate_itt"))
    choose "2020 to 2021"
    click_on "Continue"

    # - Which subject did you do your undergraduate ITT in
    expect(page).to have_text("Which subject")
    choose "Mathematics"
    click_on "Continue"

    # - Do you teach mathematics now?
    expect(page).to have_text(I18n.t("additional_payments.questions.teaching_subject_now"))
    choose "Yes"
    click_on "Continue"

    # User goes back in the journey and changes their answer to a question which resets other dependent answers
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "qualification")
    expect(page).to have_text(I18n.t("additional_payments.forms.qualification.questions.which_route"))
    choose "Undergraduate initial teacher training (ITT)"
    click_on "Continue"

    expect(page).to have_text(I18n.t("additional_payments.questions.itt_academic_year.qualification.undergraduate_itt"))
    choose "2020 to 2021"
    click_on "Continue"

    # User should be redirected to the next question which was previously answered but wiped by the attribute dependency
    expect(page).to have_text("Which subject")

    # User tries to skip ahead and not answer the question
    visit claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "teaching-subject-now")

    # User should be redirected to the dependent question still unanswered
    expect(page).to have_text("Which subject")
  end
end
