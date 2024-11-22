class StudentLoanPlanCheckJob < ApplicationJob
  APPLICABLE_POLICIES = [
    Policies::EarlyCareerPayments,
    Policies::LevellingUpPremiumPayments,
    Policies::FurtherEducationPayments,
    Policies::EarlyYearsPayments
  ].freeze

  def perform
    delete_no_data_student_loan_plan_tasks
    claims = current_year_claims_awaiting_decision.awaiting_task("student_loan_plan")
    claims.each do |claim|
      ClaimStudentLoanDetailsUpdater.call(claim)
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan.new(claim:).perform
    rescue => e
      # If something goes wrong, log the error and continue
      Rollbar.error(e)
    end
  end

  private

  def delete_no_data_student_loan_plan_tasks
    claim_ids = current_year_claims_with_no_data_tasks.pluck(:id)

    claim_ids.each_slice(500) do |ids|
      Task.where(claim_id: ids, name: "student_loan_plan", claim_verifier_match: nil, manual: false).destroy_all
    end
  end

  def current_year_claims_with_no_data_tasks
    current_year_claims_awaiting_decision.joins(:tasks).where(tasks: {name: "student_loan_plan", claim_verifier_match: nil, manual: false})
  end

  def current_year_claims_awaiting_decision
    Claim::ClaimsAwaitingDecisionFinder.new(policies: APPLICABLE_POLICIES).claims_submitted_without_slc_data
  end
end
