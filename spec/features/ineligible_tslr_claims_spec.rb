require "rails_helper"

RSpec.feature "Ineligible Teacher Student Loan Repayments claims" do
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
    expect(page).to have_text("Hampstead School is not an eligible school")
  end

  scenario "no longer teaching" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose_still_teaching "No"

    expect(claim.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You must be still working as a teacher to be eligible")
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
    expect(page).to have_text("You must have spent at least half your time teaching an eligible subject.")
  end

  scenario "does not teach an eligible subject" do
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
    expect(page).to have_text("You must have spent at least half your time teaching an eligible subject.")
  end
end
