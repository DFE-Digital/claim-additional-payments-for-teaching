require "rails_helper"

RSpec.feature "Searching for school during Teacher Student Loan Repayments claims" do
  scenario "doesn't select a school from the search results the first time around" do
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

    click_on "Continue"

    expect(page).to have_text("There is a problem")
    expect(page).to have_text("Select a school from the list")

    choose "Penistone Grammar School"
    click_on "Continue"

    expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
    expect(page).to have_text("Are you still employed to teach at a school in the UK")
  end
end
