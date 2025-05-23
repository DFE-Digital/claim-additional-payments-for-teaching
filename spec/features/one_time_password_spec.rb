require "rails_helper"

RSpec.feature "One time password" do
  let(:session) { Journeys::TargetedRetentionIncentivePayments::Session.order(:created_at).last }

  before do
    FeatureFlag.enable!(:tri_only_journey)
    create(:journey_configuration, :targeted_retention_incentive_payments_only)
    start_targeted_retention_incentive_payments_claim
    session.update!(
      answers: attributes_for(
        :targeted_retention_incentive_payments_answers,
        :submittable,
        email_address: nil,
        email_verified: nil,
        email_verification_secret: nil,
        sent_one_time_password_at: nil,
        provide_mobile_number: true,
        mobile_number: nil
      )
    )
    jump_to_claim_journey_page(
      slug: "email-address",
      journey_session: Journeys::TargetedRetentionIncentivePayments::Session.last
    )
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"
  end

  scenario "that is wrong" do
    fill_in "claim-one-time-password-field", with: "000000"
    click_on "Confirm"
    expect(page).to have_text("Enter a valid passcode")
    expect(session.answers.email_verified).to_not equal(true)
  end

  scenario "that is expired" do
    travel 20.minutes
    fill_in "claim-one-time-password-field", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to have_text("Your passcode has expired, request a new one")
    expect(session.reload.answers.email_verified).to_not equal(true)
  end

  scenario "that is valid" do
    fill_in "claim-one-time-password-field", with: get_otp_from_email
    click_on "Confirm"
    expect(page).to_not have_css(".govuk-error-summary")
    expect(session.reload.answers.email_verified).to equal(true)
  end
end
