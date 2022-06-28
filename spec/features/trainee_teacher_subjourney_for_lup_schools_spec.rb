require "rails_helper"

RSpec.feature "Trainee teacher subjourney for LUP schools" do
  scenario "non-LUP school" do
    non_lup_school = schools(:penistone_grammar_school)
    expect(LevellingUpPremiumPayments::SchoolEligibility.new(non_lup_school)).not_to be_eligible

    visit new_claim_path(EarlyCareerPayments.routing_name)
    choose_school non_lup_school

    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_no_link("Back")
  end

  scenario "LUP school with LUP ITT subject" do
    get_to_itt_subject_question

    choose "Mathematics"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.reason.trainee_teacher_only_in_claim_academic_year_2021"))

    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.personal_details"))
  end

  scenario "LUP school lacking LUP ITT subject" do
    get_to_itt_subject_question

    choose "None of the above"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_no_link("Back")
  end

  scenario "LUP school with non-LUP ITT subject but eligible degree" do
    pending("Will work once CAPT-411 is implemented")
    get_to_itt_subject_question

    choose "None of the above"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))

    choose "Yes"
    click_on "Continue"

    I18n.t("early_career_payments.ineligible.reason.trainee_teacher_only_in_claim_academic_year_2021")

    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.personal_details"))
  end

  scenario "LUP school with non-LUP ITT subject and no eligible degree" do
    pending("Will work once CAPT-411 is implemented")
    get_to_itt_subject_question

    choose "None of the above"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_degree_subject"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.ineligible.heading"))
    expect(page).to have_no_link("Back")
  end

  private

  def get_to_itt_subject_question
    lup_school = schools(:hampstead_school)
    expect(LevellingUpPremiumPayments::SchoolEligibility.new(lup_school)).to be_eligible

    visit new_claim_path(EarlyCareerPayments.routing_name)
    choose_school lup_school

    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"))

    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject_trainee_teacher"))
  end
end
