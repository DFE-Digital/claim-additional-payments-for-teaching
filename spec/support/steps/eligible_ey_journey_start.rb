def when_early_years_payment_provider_start_journey_completed
  when_early_years_payment_provider_start_journey_configuration_exists
  when_eligible_ey_provider_exists
  visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
  click_link "Start now"
  fill_in "Email address", with: "johndoe@example.com"
  click_on "Submit"
end
