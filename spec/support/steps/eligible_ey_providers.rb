def when_eligible_ey_provider_exists
  unless Policies::EarlyYearsPayments::EligibleEyProvider.any?
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )
  end
end
