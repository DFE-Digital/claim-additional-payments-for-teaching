require "rails_helper"

RSpec.feature "Searching for school during Teacher Student Loan Repayments claims" do
  scenario "doesn't select a school from the search results the first time around" do
    claim = start_tslr_claim
    choose_qts_year

    fill_in "School name", with: "Penistone"
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

    fill_in "School name", with: "hamp"
    click_on "Search"

    click_on "Search again"

    fill_in "School name", with: "penistone"
    click_on "Search"

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")
  end
end
