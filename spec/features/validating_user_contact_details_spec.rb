require "rails_helper"

RSpec.feature "Confirming Claimant Contact details" do
  it "redirects to 'email-address' if 'Use a different email address' is clicked on the One Time Password page" do
    claim = start_early_career_payments_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    claim.update!(email_address: "david.tau@gmail.com")

    expect(claim.reload.email_address).to eql("david.tau@gmail.com")
    expect(claim.email_address).not_to eql("david.tau1988@hotmail.co.uk")

    visit claim_path(claim.policy.routing_name, "email-verification")

    expect(page).to have_text("Enter the 6-digit password")
    expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "email-address"))

    click_link("Use a different email address")

    expect(page).to have_text("Personal details")
    expect(page).to have_text("Email address")

    fill_in "claim_email_address", with: "david.tau1988@hotmail.co.uk"

    click_on "Continue"

    expect(claim.reload.email_address).not_to eql("david.tau@gmail.com")
    expect(claim.email_address).to eql("david.tau1988@hotmail.co.uk")
  end
end
