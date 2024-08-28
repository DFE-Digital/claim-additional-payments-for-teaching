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

  check "I confirm that at least 70% of Bobby’s time in their job is spent working directly with children."
  click_button "Continue"

  choose "No"
  click_button "Continue"

  fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
  click_button "Continue"
end
