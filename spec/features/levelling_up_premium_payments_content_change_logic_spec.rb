require "rails_helper"

RSpec.feature "Selecting 2017 for LUP-only claim" do
  before do
    claim = start_early_career_payments_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
  end

  it "shows foreign languages only for 2017" do
    visit claim_path(claim.policy.routing_name, "itt-year")
    choose "2017 to 2018"
    click_on "Continue"
    expect(page).not_to have_text("Foreign Languages")

    click_on "Back"
    choose "2018 to 2019"
    click_on "Continue"
    expect(page).to have_text("Foreign languages")
  end
end
