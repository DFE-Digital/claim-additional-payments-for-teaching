# Run me with `rails runner db/data/20260730135238_persist_task_qualifications.rb`

relevant_policies = [
  Policies::StudentLoans,
  Policies::EarlyCareerPayments,
  Policies::TargetedRetentionIncentivePayments
]

relevant_policies.each do |policy|
  puts "policy: #{policy}"
  claims = Claim.where(policy:)
  puts "claims: #{claims.count}"
  tasks = Task.where(name: "qualifications", claim: claims)
  puts "tasks: #{tasks.count}"
  delta = claims.pluck(:id) - tasks.pluck(:claim_id)
  puts "delta: #{delta.count}"

  claims_without_task = Claim.where(id: delta)

  claims_without_task.find_each do |claim|
    dqt_teacher_status = if claim.has_dqt_record?
      Dqt::Teacher.new(claim.dqt_teacher_status)
    elsif claim.eligibility.teacher_reference_number.present?
      Dqt::Client.new.teacher.find(
        claim.eligibility.teacher_reference_number,
        include: "alerts,induction,routesToProfessionalStatuses"
      )
    end

    next if dqt_teacher_status.nil?

    verifier = AutomatedChecks::ClaimVerifiers::Qualifications.new(
      claim:,
      dqt_teacher_status:
    )
    verifier.perform
  end
end
