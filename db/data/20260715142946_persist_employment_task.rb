# Run me with `rails runner db/data/20260715142946_persist_employment_task.rb`

relevant_policies = [
  Policies::StudentLoans,
  Policies::TargetedRetentionIncentivePayments,
  Policies::FurtherEducationPayments,
  Policies::EarlyCareerPayments
]

relevant_policies.each do |policy|
  puts "policy: #{policy}"
  claims = Claim.where(policy:)
  puts "claims: #{claims.count}"
  tasks = Task.where(name: "employment", claim: claims)
  puts "tasks: #{tasks.count}"
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)
  puts "delta: #{delta.count}"

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    verifier = AutomatedChecks::ClaimVerifiers::Employment.new(claim:)
    verifier.perform
  end
end
