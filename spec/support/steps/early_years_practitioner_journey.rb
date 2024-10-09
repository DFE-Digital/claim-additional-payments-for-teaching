def when_personal_details_entered_up_to_email_address
  visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=user@example.com"
  fill_in "Claim reference number", with: claim.reference
  click_button "Submit"

  click_on "Continue"
  click_on "Continue"
  click_on "Continue"
  click_on "Continue"

  fill_in "First name", with: "John"
  fill_in "Last name", with: "Doe"
  fill_in "Day", with: "28"
  fill_in "Month", with: "2"
  fill_in "Year", with: "1988"
  fill_in "National Insurance number", with: "PX321499A"
  click_on "Continue"

  fill_in "House number or name", with: "57"
  fill_in "Building and street", with: "Walthamstow Drive"
  fill_in "Town or city", with: "Derby"
  fill_in "County", with: "City of Derby"
  fill_in "Postcode", with: "DE22 4BS"
  click_on "Continue"

  fill_in "claim-email-address-field", with: "johndoe@example.com"
  click_on "Continue"

  mail = ActionMailer::Base.deliveries.last
  otp_in_mail_sent = mail[:personalisation].unparsed_value[:one_time_password]
  fill_in "claim-one-time-password-field", with: otp_in_mail_sent
  click_on "Confirm"
end
