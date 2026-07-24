# Run me with `rails runner db/data/20260727133142_persist_matching_attributes_task.rb`

# Put your Ruby code here

claims_with_persisted_task = Task
  .matching_details
  .joins(:claim)
  .merge(Claim.by_academic_year(AcademicYear.new(2025)))
  .select(:claim_id)

claims_without_persisted_task = Claim
  .by_academic_year(AcademicYear.new(2025))
  .where.not(id: claims_with_persisted_task)

claims_without_persisted_task.find_each do |claim|
  AutomatedChecks::ClaimVerifiers::MatchingClaims.new(claim: claim).perform
end
