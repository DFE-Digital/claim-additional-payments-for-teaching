require "rails_helper"

RSpec.feature "Given a one time password" do
  let!(:drift) { OneTimePassword::Base::DRIFT }

  before do
    create(:journey_configuration, :additional_payments)
    start_early_career_payments_claim
    jump_to_claim_journey_page(
      slug: "email-address",
      journey_session: Journeys::AdditionalPaymentsForTeaching::Session.last
    )
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"
  end

  scenario "verifies the password" do
    # - that is wrong
    fill_in "claim-one-time-password-field", with: "000000"

    click_on "Confirm"
    expect(page).to have_text("Enter a valid passcode")
    session = Journeys::AdditionalPaymentsForTeaching::Session.order(:created_at).last
    expect(session.answers.email_verified).to_not equal(true)

    # - that is expired

    stub_const("OneTimePassword::Base::DRIFT", -100)

    fill_in "claim-one-time-password-field-error", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to have_text("Your passcode has expired, request a new one")
    expect(session.reload.answers.email_verified).to_not equal(true)

    # - that is valid

    stub_const("OneTimePassword::Base::DRIFT", drift)

    fill_in "claim-one-time-password-field-error", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to_not have_css(".govuk-error-summary")
    expect(session.reload.answers.email_verified).to equal(true)
  end
end
