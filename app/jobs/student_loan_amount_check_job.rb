class StudentLoanAmountCheckJob < ApplicationJob
  def perform(admin)
    delete_no_data_student_loan_amount_tasks
    claims = current_year_tslr_claims_awaiting_decision.awaiting_task("student_loan_amount")

    claims.each do |claim|
      ClaimStudentLoanDetailsUpdater.call(claim, admin)
      AutomatedChecks::ClaimVerifiers::StudentLoanAmount.new(claim:).perform
    rescue => e
      # If something goes wrong, log the error and continue
      Rollbar.error(e)
      Sentry.capture_exception(e)
    end
  end

  private

  def delete_no_data_student_loan_amount_tasks
    claim_ids = current_year_tslr_claims_with_no_data_tasks.pluck(:id)

    claim_ids.each_slice(500) do |ids|
      Task.where(claim_id: ids, name: "student_loan_amount", claim_verifier_match: nil, manual: false).destroy_all
    end
  end

  def current_year_tslr_claims_with_no_data_tasks
    current_year_tslr_claims_awaiting_decision.joins(:tasks).where(tasks: {name: "student_loan_amount", claim_verifier_match: nil, manual: false})
  end

  def current_year_tslr_claims_awaiting_decision
    Claim.by_academic_year(current_academic_year).by_policy(Policies::StudentLoans).awaiting_decision
      .where.not(submitted_using_slc_data: nil) # exclude older claims submitted using the student loan questions
    # TODO: This last condition won't be needed once we have processed all the existing TSLR claims submitted using
    # the student loan questions in the journey
  end

  def current_academic_year
    Policies::StudentLoans.current_academic_year
  end
end
