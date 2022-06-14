require "rails_helper"

RSpec.feature "Resetting dependant attributes when the claim is ineligible" do
  let(:claim) { start_early_career_payments_claim }

  before do
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
  end

  it "resets `teaching_subject_now` when `eligible_itt_subject` gets submitted" do
    visit claim_path(claim.policy.routing_name, "eligible-itt-subject")

    choose "None of the above"
    click_on "Continue"
    expect(page).to have_text("Do you have an undergraduate or postgraduate degree in an eligible subject?")

    choose "No"
    click_on "Continue"
    expect(page).to have_text("You are not eligible")

    visit claim_path(claim.policy.routing_name, "eligible-itt-subject")
    choose "None of the above"
    click_on "Continue"
    expect(page).to have_text("Do you have an undergraduate or postgraduate degree in an eligible subject?")
  end
end
