require "rails_helper"

RSpec.feature "Early years payment practitioner address", slow: true do
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }

  it_behaves_like(
    "an address journey",
    change_address_link: "Change home address",
    check_answers_heading: "Check your answers before submitting this claim"
  )

  def complete_journey_upto_postcode_search
    when_student_loan_data_exists
    when_early_years_payment_provider_authenticated_journey_submitted

    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/landing-page"
    click_link "Start now"

    fill_in "Enter your claim reference", with: Claim.last.reference
    click_button "Submit"

    mock_one_login_auth

    click_on "Continue"

    click_on "Continue"

    idv_with_one_login

    click_on "Continue"

    click_on "Continue"

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_content "What is your home address?"
  end

  def complete_journey_from_address_to_check_answers
    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    choose "No"
    click_on "Continue"

    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    choose "Female"
    click_on "Continue"

    expect(page).to have_content "Check your answers before submitting this claim"
  end
end
