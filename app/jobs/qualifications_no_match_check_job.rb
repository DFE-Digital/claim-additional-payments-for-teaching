# This job is not called anywhere in the code but can be used manually to re-run
# NO MATCH claims that initially got an incorrect response from the DQT API.
# DQT API has a limit of 300 requests/minute
# QualificationsNoMatchCheckJob.perform_later

class QualificationsNoMatchCheckJob < ApplicationJob
  def perform
    claims_with_no_match_qualification_tasks.each_slice(300) do |claims|
      Task.where(claim_id: claims.pluck(:id), name: "qualifications").delete_all

      claims.each do |claim|
        AutomatedChecks::ClaimVerifiers::Qualifications.new(
          claim: claim,
          dqt_teacher_status: Dqt::Client.new.teacher.find(
            claim.teacher_reference_number,
            birthdate: claim.date_of_birth.to_s,
            nino: claim.national_insurance_number
          )
        ).perform
      end

      sleep 60
    end
  end

  def max_attempts
    1
  end

  private

  def claims_with_no_match_qualification_tasks
    current_year_claims_awaiting_decision.joins(:tasks).where(tasks: {name: "qualifications", claim_verifier_match: :none, manual: false})
  end

  def current_year_claims_awaiting_decision
    Claim.by_academic_year(current_academic_year).awaiting_decision
  end

  def current_academic_year
    PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
  end
end
