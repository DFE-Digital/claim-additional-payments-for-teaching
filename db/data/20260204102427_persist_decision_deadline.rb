# Run me with `rails runner db/data/20260204102427_persist_decision_deadline.rb`

Policies.all.each do |policy|
  Claim.where(policy:, decision_deadline: nil).includes(:eligibility).find_each do |claim|
    claim.update(decision_deadline: claim.decision_deadline_date)
  end
end
