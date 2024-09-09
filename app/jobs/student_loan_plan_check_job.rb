class StudentLoanPlanCheckJob < ApplicationJob
  def perform
    delete_no_data_student_loan_plan_tasks
    claims = current_year_ecp_lup_fe_claims_awaiting_decision.awaiting_task("student_loan_plan")
    claims.each do |claim|
      ClaimStudentLoanDetailsUpdater.call(claim)
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan.new(claim:).perform
    end
  end

  private

  def delete_no_data_student_loan_plan_tasks
    claim_ids = current_year_ecp_lup_claims_with_no_data_tasks.pluck(:id)

    claim_ids.each_slice(500) do |ids|
      Task.where(claim_id: ids, name: "student_loan_plan", claim_verifier_match: nil, manual: false).delete_all
    end
  end

  def current_year_ecp_lup_claims_with_no_data_tasks
    current_year_ecp_lup_fe_claims_awaiting_decision.joins(:tasks).where(tasks: {name: "student_loan_plan", claim_verifier_match: nil, manual: false})
  end

  def current_year_ecp_lup_fe_claims_awaiting_decision
    Claim.by_academic_year(current_academic_year).by_policies([Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments, Policies::FurtherEducationPayments]).awaiting_decision.where(submitted_using_slc_data: false)
  end

  def current_academic_year
    Journeys.for_policy(Policies::EarlyCareerPayments).configuration.current_academic_year
  end
end
