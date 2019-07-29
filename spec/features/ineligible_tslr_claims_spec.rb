require "rails_helper"

RSpec.feature "Ineligible Teacher Student Loan Repayments claims" do
  scenario "qualified before the first eligible year" do
    claim = start_tslr_claim

    choose "Before September 1 2013"
    click_on "Continue"

    expect(claim.reload.qts_award_year).to eql("before_2013")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text(I18n.t("activerecord.errors.messages.ineligible_qts_award_year"))
  end

  scenario "now works for a different school" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose_still_teaching "Yes, at another school"

    expect(claim.reload.employment_status).to eql("different_school")

    fill_in :school_search, with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.reload.current_school).to eql schools(:hampstead_school)

    expect(page).to have_text(I18n.t("tslr.questions.subjects_taught"))
  end

  scenario "chooses an ineligible school" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:hampstead_school)

    expect(claim.reload.claim_school).to eq schools(:hampstead_school)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text(I18n.t("activerecord.errors.messages.ineligible_claim_school"))
  end

  scenario "no longer teaching" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose_still_teaching "No"

    expect(claim.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text(I18n.t("activerecord.errors.messages.employed_at_no_school"))
  end

  scenario "does not teach an eligible subject" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)
    choose_still_teaching

    choose I18n.t("tslr.questions.eligible_subjects.not_applicable")
    click_on "Continue"

    expect(claim.reload.mostly_teaching_eligible_subjects).to eq(false)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text(I18n.t("activerecord.errors.messages.not_taught_eligible_subjects_enough"))
  end

  scenario "does not teach an eligible subject for at least half of their time" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)
    choose_still_teaching

    check "Biology"
    click_on "Continue"

    choose "No"
    click_on "Continue"

    expect(claim.reload.mostly_teaching_eligible_subjects).to eq(false)
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text(I18n.t("activerecord.errors.messages.not_taught_eligible_subjects_enough"))
  end
end
