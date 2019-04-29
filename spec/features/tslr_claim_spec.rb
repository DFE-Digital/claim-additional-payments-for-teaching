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
  end

  scenario "Teacher cannot go to mid-claim page before starting a claim" do
    visit claim_path(:qts_year)
    expect(page).to have_current_path(root_path)
  end
end
