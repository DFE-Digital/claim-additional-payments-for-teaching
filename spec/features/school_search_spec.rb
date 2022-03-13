require "rails_helper"

RSpec.feature "Searching for school during Teacher Student Loan Repayments claims" do
  include StudentLoansHelper

  scenario "doesn't select a school from the search results the first time around" do
    claim = start_student_loans_claim

    fill_in :school_search, with: "Penistone"
    click_on "Search"

    click_on "Continue"

    expect(page).to have_text("There is a problem")
    expect(page).to have_text("Select a school from the list")

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.eligibility.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text(subjects_taught_question(school_name: schools(:penistone_grammar_school).name))
  end

  scenario "searches again to find school" do
    claim = start_student_loans_claim

    fill_in :school_search, with: "hamp"
    click_on "Search"

    click_on "Search again"

    fill_in :school_search, with: "penistone"
    click_on "Search"

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.eligibility.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text(subjects_taught_question(school_name: schools(:penistone_grammar_school).name))
  end

  scenario "Claim school search with autocomplete", js: true do
    start_student_loans_claim

    expect(page).to have_text(claim_school_question)
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"
    find("li", text: schools(:penistone_grammar_school).name).click

    expect(page).to have_button("Continue")

    click_button "Continue"

    expect(page).to have_text(subjects_taught_question(school_name: schools(:penistone_grammar_school).name))
  end

  scenario "Current school search with autocomplete", js: true do
    start_student_loans_claim

    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught

    choose_still_teaching "Yes, at another school"

    expect(page).to have_text(I18n.t("questions.current_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"
    using_wait_time 8 do
      find("li", text: schools(:penistone_grammar_school).name).click
    end

    expect(page).to have_button("Continue")

    click_button "Continue"

    expect(page).to have_text(leadership_position_question)
  end

  scenario "School search form still works like a normal form if submitted", js: true do
    start_student_loans_claim

    expect(page).to have_text(claim_school_question)
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"

    expect(page).to have_text(schools(:penistone_grammar_school).name)
    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_text("Select your school from the search results.")
    expect(page).to have_text(schools(:penistone_grammar_school).name)
  end

  scenario "Editing school search after autocompletion clears last selection", js: true do
    start_student_loans_claim

    expect(page).to have_text(claim_school_question)
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Penistone"
    find("li", text: schools(:penistone_grammar_school).name).click

    expect(page).to have_button("Continue")

    fill_in :school_search, with: "Hampstead"

    using_wait_time 8 do
      expect(page).to have_text(schools(:hampstead_school).name)
    end
    expect(page).to have_button("Search")

    click_button "Search"

    expect(page).to have_text("Select your school from the search results.")
    expect(page).to have_text(schools(:hampstead_school).name)
  end

  scenario "Claim school search includes closed schools" do
    start_student_loans_claim

    expect(page).to have_text(claim_school_question)
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Lister"
    click_button "Search"

    expect(page).to have_text(schools(:the_samuel_lister_academy).name)
  end

  scenario "Current school search excludes closed schools" do
    start_student_loans_claim
    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught
    choose_still_teaching "Yes, at another school"

    expect(page).to have_text(I18n.t("questions.current_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Lister"
    click_button "Search"

    expect(page).not_to have_text(schools(:the_samuel_lister_academy).name)
  end

  scenario "Claim school search with autocomplete includes closed schools", js: true do
    start_student_loans_claim

    expect(page).to have_text(claim_school_question)
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Lister"
    expect(page).to have_text(schools(:the_samuel_lister_academy).name)
  end

  scenario "Current school search with autocomplete excludes closed schools", js: true do
    start_student_loans_claim

    choose_school schools(:penistone_grammar_school)
    choose_subjects_taught
    choose_still_teaching "Yes, at another school"

    expect(page).to have_text(I18n.t("questions.current_school"))
    expect(page).to have_button("Search")

    fill_in :school_search, with: "Lister"
    expect(page).not_to have_text(schools(:the_samuel_lister_academy).name)
  end
end
