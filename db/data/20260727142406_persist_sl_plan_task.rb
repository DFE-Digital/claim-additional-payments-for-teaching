# Run me with `rails runner db/data/20260727142406_persist_sl_plan_task.rb`

admin = DfeSignIn::User.find("6b15ba5b-8f3a-48ed-bb7f-721630ffdf6a")

relevant_policies = Policies
  .all
  .select(&:auto_check_student_loan_plan_task?)

relevant_policies.each do |policy|
  puts "policy: #{policy}"
  claims = Claim.where(policy:)
  puts "claims: #{claims.count}"
  tasks = Task.where(name: "student_loan_plan", claim: claims)
  puts "tasks: #{tasks.count}"
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)
  puts "delta: #{delta.count}"

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    next unless claim.amendable?

    ClaimStudentLoanDetailsUpdater.call(claim, admin)
    AutomatedChecks::ClaimVerifiers::StudentLoanPlan.new(claim:).perform
  end
end
