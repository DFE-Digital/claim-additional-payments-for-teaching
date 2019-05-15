require "rails_helper"

RSpec.feature "Teacher Student Loan Repayments claims" do
  scenario "Teacher claims back student loan repayments" do
    visit root_path

    click_on "Agree and continue"

    claim = TslrClaim.order(:created_at).last

    expect(page).to have_text("Which academic year were you awarded qualified teacher status")
    select "September 1 2014 - August 31 2015", from: :tslr_claim_qts_award_year
    click_on "Continue"

    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text("Which school were you employed at between")

    fill_in "School name", with: "Penistone"
    click_on "Search"

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")

    choose "Yes, at Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.employment_status).to eql("claim_school")
    expect(claim.current_school).to eql(schools(:penistone_grammar_school))
    expect(page).to have_text("Did you teach")
  end

  scenario "Teacher now works for a different school" do
    visit root_path

    click_on "Agree and continue"

    claim = TslrClaim.order(:created_at).last

    expect(page).to have_text("Which academic year were you awarded qualified teacher status")
    select "September 1 2014 - August 31 2015", from: :tslr_claim_qts_award_year
    click_on "Continue"

    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text("Which school were you employed at between")

    fill_in "School name", with: "Penistone"
    click_on "Search"

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")

    choose "Yes, at another school"
    click_on "Continue"

    expect(claim.reload.employment_status).to eql("different_school")

    fill_in "School name", with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.reload.current_school).to eql schools(:hampstead_school)
    expect(page).to have_text("Did you teach")
  end

  scenario "chooses an ineligible school" do
    visit root_path

    click_on "Agree and continue"

    claim = TslrClaim.order(:created_at).last

    expect(page).to have_text("Which academic year were you awarded qualified teacher status")
    select "September 1 2014 - August 31 2015", from: :tslr_claim_qts_award_year
    click_on "Continue"

    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text("Which school were you employed at between")

    fill_in "School name", with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eq schools(:hampstead_school)
    expect(page).to have_text("You’re not eligible")
  end

  scenario "no longer teaching" do
    visit root_path

    click_on "Agree and continue"

    claim = TslrClaim.order(:created_at).last

    expect(page).to have_text("Which academic year were you awarded qualified teacher status")
    select "September 1 2014 - August 31 2015", from: :tslr_claim_qts_award_year
    click_on "Continue"

    expect(claim.reload.qts_award_year).to eql("2014-2015")
    expect(page).to have_text("Which school were you employed at between")

    fill_in "School name", with: "Penistone"
    click_on "Search"

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in England")

    choose "No"
    click_on "Continue"

    expect(claim.reload.employment_status).to eq("no_school")
    expect(page).to have_text("You’re not eligible")
  end

  scenario "Teacher cannot go to mid-claim page before starting a claim" do
    visit claim_path("qts-year")
    expect(page).to have_current_path(root_path)
  end
end
