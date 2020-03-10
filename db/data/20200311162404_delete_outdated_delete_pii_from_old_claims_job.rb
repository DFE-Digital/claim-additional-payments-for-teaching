# Run me with `rails runner db/data/20200311162404_delete_outdated_delete_pii_from_old_claims_job.rb`

Delayed::Job.where("handler LIKE ?", "%DeletePiiFromOldClaimsJob%").delete_all
