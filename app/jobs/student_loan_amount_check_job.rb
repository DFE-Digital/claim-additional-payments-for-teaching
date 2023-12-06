class StudentLoanAmountCheckJob < ApplicationJob
  def perform
    delete_no_data_student_loan_amount_tasks
    claims = current_year_tslr_claims.awaiting_task("student_loan_amount")

    claims.each do |claim|
      AutomatedChecks::ClaimVerifiers::StudentLoanAmount.new(claim: claim).perform
    end
  end

  private

  def delete_no_data_student_loan_amount_tasks
    claim_ids = current_year_tslr_claims_with_no_data_tasks.pluck(:id)

    claim_ids.each_slice(500) do |ids|
      Task.where(claim_id: ids, name: "student_loan_amount", claim_verifier_match: nil).delete_all
    end
  end

  def current_year_tslr_claims_with_no_data_tasks
    current_year_tslr_claims.joins(:tasks).where(tasks: {name: "student_loan_amount", claim_verifier_match: nil})
  end

  def current_year_tslr_claims
    Claim.by_academic_year(current_academic_year).by_policy(StudentLoans)
  end

  def current_academic_year
    PolicyConfiguration.for(StudentLoans).current_academic_year
  end
end
