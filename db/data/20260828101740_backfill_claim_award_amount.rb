# Run me with `rails runner db/data/20260828101740_backfill_claim_award_amount.rb`

Policies.all.each do |policy|
  Claim
    .where(policy: policy)
    .with_eligibility_award_amounts
    .update_all("award_amount = eligibility_award_amount")
end
