class StudentLoanPlanCheckJob < ApplicationJob
  def perform(admin)
    claims = current_year_claims_awaiting_decision
      .joins(:tasks)
      .where(
        tasks: {
          name: "student_loan_plan"
        }
      ).merge(Task.awaiting_passed_result)

    claims_without_task = current_year_claims_awaiting_decision
      .awaiting_task("student_loan_plan")

    claims.each do |claim|
      ClaimStudentLoanDetailsUpdater.call(claim, admin)
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan.new(claim:).perform
    rescue => e
      # If something goes wrong, log the error and continue
      Sentry.capture_exception(e)
    end

    claims_without_task.each do |claim|
      ClaimStudentLoanDetailsUpdater.call(claim, admin)
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan.new(claim:).perform
    rescue => e
      # If something goes wrong, log the error and continue
      Sentry.capture_exception(e)
    end
  end

  private

  def applicable_policies
    Policies.all.select(&:auto_check_student_loan_plan_task?)
  end

  def current_year_claims_awaiting_decision
    applicable_policies.map do |policy|
      journey = Journeys.for_policy(policy)

      next if journey.nil? # ECP

      journey_configuration = journey.configuration

      Claim
        .by_academic_year(journey_configuration.current_academic_year)
        .by_policy(policy)
        .awaiting_decision
    end.compact.reduce(&:or)
  end
end
