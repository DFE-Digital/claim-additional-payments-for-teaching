def when_early_years_payment_provider_authenticated_journey_ready_to_submit
  visit magic_link
  check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
  click_button "Continue"

  choose nursery.nursery_name
  click_button "Continue"

  fill_in "claim-paye-reference-field", with: "123/123456SE90"
  click_button "Continue"

  fill_in "First name", with: "Bobby"
  fill_in "Last name", with: "Bobberson"
  click_button "Continue"

  date = Date.yesterday
  fill_in("Day", with: date.day)
  fill_in("Month", with: date.month)
  fill_in("Year", with: date.year)
  click_button "Continue"

  choose "Yes"
  click_button "Continue"

  choose "No"
  click_button "Continue"

  fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
  click_button "Continue"
end

def when_early_years_payment_provider_authenticated_journey_submitted
  when_early_years_payment_provider_authenticated_journey_configuration_exists
  when_early_years_payment_provider_start_journey_completed
  when_early_years_payment_provider_authenticated_journey_ready_to_submit

  fill_in "claim-provider-contact-name-field", with: "John Doe"
  click_button "Accept and send"
end
