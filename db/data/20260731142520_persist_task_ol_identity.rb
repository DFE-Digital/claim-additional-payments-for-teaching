# Run me with `rails runner db/data/20260731142520_persist_task_ol_identity.rb`

relevant_policies = [
  Policies::FurtherEducationPayments,
  Policies::EarlyYearsPayments,
  Policies::EarlyYearsTeachersFinancialIncentivePayments
]

relevant_policies.each do |policy|
  puts "policy: #{policy}"
  claims = Claim.where(policy:)
  puts "claims: #{claims.count}"
  tasks = Task.where(name: "one_login_identity", claim: claims)
  puts "tasks: #{tasks.count}"
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)
  puts "delta: #{delta.count}"

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    next if claim.tasks.where(name: "identity_confirmation").exists?
    next if claim.tasks.where(name: "ey_alternative_verification").exists?

    if claim.policy == Policies::EarlyYearsPayments
      next unless claim.eligibility.practitioner_journey_completed?
    end

    verifier = AutomatedChecks::ClaimVerifiers::OneLoginIdentity.new(claim:)
    verifier.perform
  end
end
