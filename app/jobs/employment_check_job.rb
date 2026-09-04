class EmploymentCheckJob < ApplicationJob
  def perform
    claims_with_tasks = claims_awaiting_decision_without_passed_check

    claims_with_tasks.each do |claim|
      AutomatedChecks::ClaimVerifiers::Employment.new(claim:).perform
    end

    claims_without_tasks = claims_awaiting_decision
      .awaiting_task("employment")
      .includes(eligibility: [:current_school, :claim_school])

    claims_without_tasks.each do |claim|
      next unless claim.policy.has_verifier_for_claim?(claim:, verifier: AutomatedChecks::ClaimVerifiers::Employment)

      AutomatedChecks::ClaimVerifiers::Employment.new(claim:).perform
    end
  end

  private

  def claims_awaiting_decision_without_passed_check
    claims_awaiting_decision
      .joins(:tasks)
      .where(tasks: {
        name: "employment",
        passed: [nil, false]
      })
      .where("tasks.updated_at > ?", 3.months.ago)
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
