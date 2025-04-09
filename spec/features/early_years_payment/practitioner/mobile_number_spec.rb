require "rails_helper"

RSpec.feature "Early years payment practitioner mobile number" do
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
  let(:notify_sms_message) { instance_double(NotifySmsMessage, deliver!: true) }

  before do
    allow(NotifySmsMessage).to receive(:new).with(
      phone_number: "07700900001",
      template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
      personalisation: {
        otp: otp_code
      }
    ).and_return(notify_sms_message)
    allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double(OneTimePassword::Generator, code: otp_code))
    allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double(OneTimePassword::Validator, valid?: true))
  end

  scenario "Enter and validate mobile number" do
    when_early_years_payment_practitioner_journey_configuration_exists
    when_personal_details_entered_up_to_email_address

    expect(page).to have_content("Can we use your mobile number to contact you?")
    choose "Yes"
    click_on "Continue"

    fill_in "Your mobile number", with: "07700900001"
    click_on "Continue"
    expect(notify_sms_message).to have_received(:deliver!).once

    fill_in "Enter the 6-digit passcode", with: otp_code
    click_on "Confirm"
    expect(journey_session.answers.mobile_number).to eq "07700900001"
    expect(journey_session.answers.mobile_verified).to be true

    expect(page).to have_content("Your personal bank account details")
  end

  scenario "Resend passcode" do
    when_early_years_payment_practitioner_journey_configuration_exists
    when_personal_details_entered_up_to_email_address

    expect(page).to have_content("Can we use your mobile number to contact you?")
    choose "Yes"
    click_on "Continue"

    fill_in "Your mobile number", with: "07700900001"
    click_on "Continue"

    click_link "Resend passcode"
    click_on "Continue"

    expect(notify_sms_message).to have_received(:deliver!).twice
  end
end
