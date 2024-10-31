def when_eligible_ey_provider_exists
  create(:eligible_ey_provider, primary_key_contact_email_address: "johndoe@example.com", secondary_contact_email_address: "janedoe@example.com") unless EligibleEyProvider.any?
end
