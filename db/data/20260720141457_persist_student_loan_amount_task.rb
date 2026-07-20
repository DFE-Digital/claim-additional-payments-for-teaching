# Run me with `rails runner db/data/20260720141457_persist_student_loan_amount_task.rb`

relevant_policies = [
  Policies::StudentLoans
]

relevant_policies.each do |policy|
  claims = Claim.where(policy:)
  tasks = Task.where(name: "student_loan_amount", claim: claims)
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    verifier = AutomatedChecks::ClaimVerifiers::StudentLoanAmount.new(claim:)
    verifier.perform
  end
end
