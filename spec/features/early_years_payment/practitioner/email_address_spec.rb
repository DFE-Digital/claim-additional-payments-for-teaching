require "rails_helper"

RSpec.feature "Early years payment practitioner email address" do
  let(:claim) do
    create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      reference: "foo",
      practitioner_email_address: "practitioner@example.com"
    )
  end
  let(:otp_code) { "123456" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Start::Session.last }

  scenario "Resend passcode for unverified email" do
    when_early_years_payment_practitioner_journey_configuration_exists
    when_personal_details_entered_up_to_address

    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"
    expect(ActionMailer::Base.deliveries.count).to eq 1

    click_link "Resend passcode"
    click_on "Continue"

    expect(ActionMailer::Base.deliveries.count).to eq 2
  end

  scenario "Resend passcode for verified email" do
    when_early_years_payment_practitioner_journey_configuration_exists
    when_personal_details_entered_up_to_address

    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].unparsed_value[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    click_link "Back"
    click_link "Resend passcode"
    click_on "Continue"

    expect(ActionMailer::Base.deliveries.count).to eq 2
  end

  scenario "Change email address for unverified email" do
    when_early_years_payment_practitioner_journey_configuration_exists
    when_personal_details_entered_up_to_address

    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"
    expect(ActionMailer::Base.deliveries.count).to eq 1

    click_link "Resend passcode"

    fill_in "claim-email-address-field", with: "different@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    expect(ActionMailer::Base.deliveries.count).to eq 2
  end
end
