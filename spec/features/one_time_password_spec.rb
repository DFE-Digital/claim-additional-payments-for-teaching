require "rails_helper"

RSpec.feature "Given a one time password" do
  let(:claim) { start_early_career_payments_claim }
  before do
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    visit claim_path(claim.policy.routing_name, "email-address")
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"
  end

  scenario "that is valid" do
    fill_in "claim_one_time_password", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to_not have_css(".govuk-error-summary")
    expect(Claim.by_policy(EarlyCareerPayments).order(:created_at).last.email_verified).to equal(true)
  end

  scenario "that is expired" do
    stub_const("OneTimePassword::Base::DRIFT", -100)
    fill_in "claim_one_time_password", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to have_text("Your passcode has expired, request a new one")
    expect(Claim.by_policy(EarlyCareerPayments).order(:created_at).last.email_verified).to_not equal(true)
  end

  scenario "that is wrong" do
    fill_in "claim_one_time_password", with: "000000"
    click_on "Confirm"
    expect(page).to have_text("Enter a valid passcode")
    expect(Claim.by_policy(EarlyCareerPayments).order(:created_at).last.email_verified).to_not equal(true)
  end
end
