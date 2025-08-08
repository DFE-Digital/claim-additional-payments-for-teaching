def when_personal_details_entered_up_to_address
  visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"
  fill_in "Enter your claim reference", with: claim.reference
  click_button "Submit"

  mock_one_login_auth

  expect(page).to have_content "Sign in with GOV.UK One Login"
  click_on "Continue"

  mock_one_login_idv

  expect(page).to have_content "You’ve successfully signed in to GOV.UK One Login"
  click_on "Continue"

  expect(page).to have_content "You’ve successfully proved your identity with GOV.UK One Login"
  click_on "Continue"

  expect(page).to have_content "How we will use your information"
  click_on "Continue"

  fill_in "First name", with: "John"
  fill_in "Last name", with: "Doe"
  fill_in "Day", with: "28"
  fill_in "Month", with: "2"
  fill_in "Year", with: "1988"
  fill_in "National Insurance number", with: "PX321499A"
  click_on "Continue"

  expect(page.title).to have_text("What is your home address?")
  expect(page).to have_content("What is your home address?")
  click_on("Enter your address manually")

  expect(page.title).to have_text("What is your address?")
  expect(page).to have_content("What is your address?")
  fill_in "House number or name", with: "57"
  fill_in "Building and street", with: "Walthamstow Drive"
  fill_in "Town or city", with: "Derby"
  fill_in "County", with: "City of Derby"
  fill_in "Postcode", with: "DE22 4BS"
  click_on "Continue"
end

def when_personal_details_entered_up_to_email_address
  when_personal_details_entered_up_to_address

  fill_in "claim-email-address-field", with: "johndoe@example.com"
  click_on "Continue"

  mail = ActionMailer::Base.deliveries.last
  otp_in_mail_sent = mail.personalisation[:one_time_password]
  fill_in "claim-one-time-password-field", with: otp_in_mail_sent
  click_on "Confirm"
end

def when_early_years_practitioner_claim_submitted
  when_early_years_payment_practitioner_journey_configuration_exists
  when_early_years_payment_provider_authenticated_journey_submitted
  when_personal_details_entered_up_to_email_address

  choose "No"
  click_on "Continue"

  fill_in "Name on the account", with: "Jo Bloggs"
  fill_in "Sort code", with: "123456"
  fill_in "Account number", with: "87654321"
  click_on "Continue"

  choose "Female"
  click_on "Continue"

  perform_enqueued_jobs { click_on "Accept and send" }
end
