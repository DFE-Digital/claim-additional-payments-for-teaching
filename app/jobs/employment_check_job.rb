class EmploymentCheckJob < ApplicationJob
  def perform
    delete_no_data_employment_tasks
    claims = current_year_claims.awaiting_task("employment")

    claims.each do |claim|
      AutomatedChecks::ClaimVerifiers::Employment.new(
        claim: claim
      ).perform
    end
  end

  private

  def delete_no_data_employment_tasks
    claim_ids = current_year_claims_with_no_data_employment_tasks.pluck(:id)

    claim_ids.each_slice(500) do |ids|
      Task.where(claim_id: ids, name: "employment", claim_verifier_match: nil).delete_all
    end
  end

  def current_year_claims_with_no_data_employment_tasks
    current_year_claims.joins(:tasks).where(tasks: {name: "employment", claim_verifier_match: nil})
  end

  def current_year_claims
    Claim.by_academic_year(current_academic_year)
  end

  def current_academic_year
    PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
  end
end
