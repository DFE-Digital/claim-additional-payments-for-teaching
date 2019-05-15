require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    claim = start_tslr_claim
    expect(page).to have_text("Which academic year were you awarded qualified teacher status")

    choose_qts_year
    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text("Which school were you employed at between")

    choose_school schools(:penistone_grammar_school)
    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")

    choose "Yes, at Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.employment_status).to eql("claim_school")
    expect(claim.current_school).to eql(schools(:penistone_grammar_school))

    expect(page).to have_text("What is your full name")

    fill_in "What is your full name?", with: "Margaret Honeycutt"
    click_on "Continue"

    expect(claim.reload.full_name).to eql("Margaret Honeycutt")

    expect(page).to have_text("Claim complete")
  end

  scenario "Teacher now works for a different school" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)

    choose "Yes, at another school"
    click_on "Continue"

    expect(claim.reload.employment_status).to eql("different_school")

    fill_in "School name", with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.reload.current_school).to eql schools(:hampstead_school)

    expect(page).to have_text("What is your full name")
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

    choose "No"
    click_on "Continue"

    expect(claim.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You must be still working as a teacher to be eligible")
  end

  scenario "Teacher cannot go to mid-claim page before starting a claim" do
    visit claim_path("qts-year")
    expect(page).to have_current_path(root_path)
  end
end
