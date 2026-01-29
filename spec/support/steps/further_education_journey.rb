def when_further_education_journey_ready_to_submit
  when_dqt_stubbed
  when_further_education_payments_journey_configuration_exists
  college

  visit landing_page_path(Journeys::FurtherEducationPayments.routing_name)
  click_link "Start now"

  expect(page).to have_content("Do you have a")
  choose "No"
  click_button "Continue"

  expect(page).to have_content("Did you apply for a")
  choose "No"
  click_button "Continue"

  expect(page).to have_content("Make a claim for a targeted retention incentive payment for further education")
  click_button "Start eligibility check"

  choose "Yes"
  click_button "Continue"

  fill_in "claim[provision_search]", with: college.name
  click_button "Continue"

  choose college.name
  click_button "Continue"

  choose("September 2023 to August 2024")
  click_button "Continue"
  choose "Yes"
  click_button "Continue"

  choose("Permanent")
  click_button "Continue"

  choose("12 or more hours per week, but fewer than 20")
  click_button "Continue"

  expect(page).to have_content("Do you spend at least half of your timetabled teaching hours teaching students on 16 to 19 study programmes, T Levels or 16 to 19 apprenticeships?")
  choose "Yes"
  click_button "Continue"

  check("Physics")
  click_button "Continue"

  check "A or AS level physics"
  click_button "Continue"

  choose("Yes")
  click_button "Continue"

  within all(".govuk-fieldset")[0] do
    choose("No")
  end

  within all(".govuk-fieldset")[1] do
    choose("No")
  end

  click_button "Continue"

  click_button "Continue"

  click_button "Apply now"

  sign_in_with_one_login
  idv_with_one_login

  click_button "Continue"

  expect(page).to have_content("Personal details")
  expect(page).to have_content("Enter your National Insurance number")
  fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
  click_on "Continue"

  click_button("Enter your address manually")
  fill_in "House number or name", with: "57"
  fill_in "Building and street", with: "Walthamstow Drive"
  fill_in "Town or city", with: "Derby"
  fill_in "County", with: "City of Derby"
  fill_in "Postcode", with: "DE22 4BS"
  click_on "Continue"

  fill_in "Email address", with: "johndoe@example.com"
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

  check "claim-claimant-declaration-1-field"
end
