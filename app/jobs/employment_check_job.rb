class EmploymentCheckJob < ApplicationJob
  def perform
    delete_employment_tasks
    claims = claims_awaiting_decision
      .awaiting_task("employment")
      .includes(eligibility: [:current_school, :claim_school])

    claims.each do |claim|
      AutomatedChecks::ClaimVerifiers::Employment.new(claim:).perform
    end
  end

  private

  def delete_employment_tasks
    claim_ids = claims_awaiting_decision_without_passed_check.pluck(:id)

    claim_ids.each_slice(500) do |ids|
      Task.where(claim_id: ids, name: "employment").destroy_all
    end
  end

  def claims_awaiting_decision_without_passed_check
    claims_awaiting_decision.joins(:tasks).where(tasks: {name: "employment", passed: [nil, false]}).where(
      "tasks.updated_at > ?", Date.today - 3.months
    )
  end

  def claims_awaiting_decision
    Claim.by_academic_year(current_academic_year).awaiting_decision
  end

  def policies_open_for_submissions
    Journeys::Configuration.where(open_for_submissions: true)
  end

  def current_academic_year
    policies_open_for_submissions.map(&:current_academic_year).max
  end
end
