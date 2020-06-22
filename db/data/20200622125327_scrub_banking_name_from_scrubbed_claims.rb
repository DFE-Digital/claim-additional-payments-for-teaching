# Run me with `rails runner db/data/20200622125327_scrub_banking_name_from_scrubbed_claims.rb`

Claim.where("personal_data_removed_at IS NOT NULL AND banking_name IS NOT NULL")
  .update_all(banking_name: nil)
