# Run me with `rails runner db/data/20260722095905_persist_task_fe_repeat_applicant.rb`

relevant_policies = [
  Policies::FurtherEducationPayments
]

relevant_academic_year = AcademicYear.new("2025/2026")

relevant_policies.each do |policy|
  claims = Claim.where(policy:, academic_year: relevant_academic_year)
  puts "claims: #{claims.count}"
  tasks = Task.where(name: "fe_repeat_applicant_check", claim: claims)
  puts "tasks: #{tasks.count}"
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)
  puts "delta: #{delta.count}"

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    verifier = AutomatedChecks::ClaimVerifiers::FeRepeatApplicantCheck.new(claim:)
    verifier.perform
  end
end
