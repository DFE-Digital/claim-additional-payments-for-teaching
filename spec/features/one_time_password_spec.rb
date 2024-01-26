require "rails_helper"

RSpec.feature "Given a one time password" do
  let!(:drift) { OneTimePassword::Base::DRIFT }

  let(:claim) { start_early_career_payments_claim }

  before do
    create(:policy_configuration, :additional_payments)
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    jump_to_claim_journey_page(claim, "email-address")
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"
  end

  scenario "verifies the password" do
    # - that is wrong
    fill_in "claim_one_time_password", with: "000000"

    click_on "Confirm"
    expect(page).to have_text("Enter a valid passcode")
    expect(Claim.by_policy(EarlyCareerPayments).order(:created_at).last.email_verified).to_not equal(true)

    # - that is expired

    stub_const("OneTimePassword::Base::DRIFT", -100)

    fill_in "claim_one_time_password", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to have_text("Your passcode has expired, request a new one")
    expect(Claim.by_policy(EarlyCareerPayments).order(:created_at).last.email_verified).to_not equal(true)

    # - that is valid

    stub_const("OneTimePassword::Base::DRIFT", drift)

    fill_in "claim_one_time_password", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to_not have_css(".govuk-error-summary")
    expect(Claim.by_policy(EarlyCareerPayments).order(:created_at).last.email_verified).to equal(true)
  end
end
