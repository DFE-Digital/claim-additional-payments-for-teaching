require "rails_helper"

RSpec.feature "Searching for school during Teacher Student Loan Repayments claims" do
  scenario "doesn't select a school from the search results the first time around" do
    claim = start_tslr_claim
    choose_qts_year

    fill_in :school_search, with: "Penistone"
    click_on "Search"

    click_on "Continue"

    expect(page).to have_text("There is a problem")
    expect(page).to have_text("Select a school from the list")

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")
  end

  scenario "searches again to find school" do
    claim = start_tslr_claim
    choose_qts_year

    fill_in :school_search, with: "hamp"
    click_on "Search"

    click_on "Search again"

    fill_in :school_search, with: "penistone"
    click_on "Search"

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")
  end

  scenario "Claim school search with autocomplete", js: true do
    start_tslr_claim
    choose_qts_year

    expect(page).to have_text(I18n.t("tslr.questions.claim_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"
    find("li", text: schools(:penistone_grammar_school).name).click

    expect(page).to have_button("Continue")

    click_button "Continue"

    expect(page).to have_text(I18n.t("tslr.questions.employment_status"))
  end

  scenario "Current school search with autocomplete", js: true do
    start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)
    choose_still_teaching "Yes, at another school"

    expect(page).to have_text(I18n.t("tslr.questions.current_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"
    find("li", text: schools(:penistone_grammar_school).name).click

    expect(page).to have_button("Continue")

    click_button "Continue"

    expect(page).to have_text(I18n.t("tslr.questions.mostly_teaching_eligible_subjects"))
  end

  scenario "School search autocomplete without JavaScript falls back to searching", js: false do
    start_tslr_claim
    choose_qts_year

    expect(page).to have_text(I18n.t("tslr.questions.claim_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"

    expect(page).not_to have_text(schools(:penistone_grammar_school).name)
    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_text("Select your school from the search results.")
    expect(page).to have_text(schools(:penistone_grammar_school).name)
  end

  scenario "School search autocomplete falls back to searching when no school is selected", js: true do
    start_tslr_claim
    choose_qts_year

    expect(page).to have_text(I18n.t("tslr.questions.claim_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"

    expect(page).to have_text(schools(:penistone_grammar_school).name)
    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_text("Select your school from the search results.")
    expect(page).to have_text(schools(:penistone_grammar_school).name)
  end

  scenario "Editing school search after autocompletion clears last selection", js: true do
    start_tslr_claim
    choose_qts_year

    expect(page).to have_text(I18n.t("tslr.questions.claim_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"
    find("li", text: schools(:penistone_grammar_school).name).click

    expect(page).to have_button("Continue")

    fill_in :school_search, with: "Hampstead"

    expect(page).to have_text(schools(:hampstead_school).name)
    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_text("Select your school from the search results.")
    expect(page).to have_text(schools(:hampstead_school).name)
  end
end
