require "rails_helper"

RSpec.feature "Confirming Claimant Contact details" do
  before { create(:journey_configuration, :additional_payments) }

  it "redirects to 'email-address' if 'Change email address' is clicked on the One Time Password page" do
    claim = start_early_career_payments_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    claim.update!(email_address: "david.tau@gmail.com")

    expect(claim.reload.email_address).to eql("david.tau@gmail.com")
    expect(claim.email_address).not_to eql("david.tau1988@hotmail.co.uk")

    jump_to_claim_journey_page(claim, "email-verification")

    expect(page).to have_text("Enter the 6-digit passcode")
    expect(page).to have_link(href: claim_path(Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME, "email-address"))

    click_link("Change email address")

    expect(page).to have_text("Personal details")
    expect(page).to have_text("Email address")

    fill_in "claim_email_address", with: "david.tau1988@hotmail.co.uk"

    click_on "Continue"

    expect(claim.reload.email_address).not_to eql("david.tau@gmail.com")
    expect(claim.email_address).to eql("david.tau1988@hotmail.co.uk")
  end
end
