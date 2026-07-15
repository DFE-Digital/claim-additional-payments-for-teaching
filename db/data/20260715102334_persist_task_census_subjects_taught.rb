# Run me with `rails runner db/data/20260715102334_persist_task_census_subjects_taught.rb`

relevant_policies = [
  Policies::StudentLoans,
  Policies::TargetedRetentionIncentivePayments,
  Policies::EarlyCareerPayments
]

relevant_policies.each do |policy|
  claims = Claim.where(policy:)
  tasks = Task.where(name: "census_subjects_taught", claim: claims)
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    verifier = AutomatedChecks::ClaimVerifiers::CensusSubjectsTaught.new(claim:)
    verifier.perform
  end
end
