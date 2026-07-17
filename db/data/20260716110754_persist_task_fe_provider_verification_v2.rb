# Run me with `rails runner db/data/20260716110754_persist_task_fe_provider_verification_v2.rb`

relevant_policies = [
  Policies::FurtherEducationPayments
]

relevant_policies.each do |policy|
  claims = Claim.where(policy:, academic_year: AcademicYear.new("2025/2026"))
  tasks = Task.where(name: "fe_provider_verification_v2", claim: claims)
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    verifier = AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2.new(claim)
    verifier.perform
  end
end
