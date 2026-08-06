# Run me with `rails runner db/data/20260806094500_backfill_claim_award_amount.rb`
#
# Copies award_amount from each claim's eligibility onto claims.award_amount, for
# claims that predate the before_save mirror on Claim.
#
# Run this AFTER the mirror has been deployed, not before: claims created or amended
# in the gap would otherwise be left behind until someone ran it again.
#
# NOTE: It's OK to do `update_all` as the `award_amount` field on claims is in the
# `analytics_blocklist.yml`, so no dfe-analytics events are missed.
#
# Matches on IS DISTINCT FROM rather than `award_amount: nil` so it also corrects rows
# that are populated but stale — an FE, TRI or TSLR claim amended between the migration
# and the mirror deploying would have a non-NULL but out of date value, and a NULL-only
# filter would skip it. That also makes this idempotent.

def drifted_claims(policy)
  eligibilities = policy::Eligibility.table_name

  Claim
    .where(eligibility_type: policy::Eligibility.name)
    .where(
      "claims.award_amount IS DISTINCT FROM " \
      "(SELECT e.award_amount FROM #{eligibilities} e WHERE e.id = claims.eligibility_id)"
    )
end

# BEFORE
Policies::POLICIES.each do |policy|
  puts "#{policy} - to backfill: #{drifted_claims(policy).count}"
end

# MIGRATE
Policies::POLICIES.each do |policy|
  eligibilities = policy::Eligibility.table_name

  drifted_claims(policy).update_all(
    "award_amount = (SELECT e.award_amount FROM #{eligibilities} e WHERE e.id = claims.eligibility_id)"
  )
end

# AFTER
Policies::POLICIES.each do |policy|
  puts "#{policy} - remaining: #{drifted_claims(policy).count}"
end
