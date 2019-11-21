require "rails_helper"

RSpec.feature "Claim journey does not get cached", js: true do
  it "redirects the user to the start of the claim journey if they go back after the claim is completed" do
    claim = start_student_loans_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:student_loans_eligibility, :eligible))
    visit claim_path(claim.policy.routing_name, "check-your-answers")

    expect(page).to have_text(claim.first_name)

    click_on "Confirm and send"

    expect(current_path).to eq(claim_confirmation_path(claim.policy.routing_name))

    page.evaluate_script("window.history.back()")

    expect(page).to_not have_text(claim.first_name)
    expect(current_path).to eq(new_claim_path(claim.policy.routing_name))
  end
end
