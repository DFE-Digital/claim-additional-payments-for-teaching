# This job is not called anywhere in the code but can be used manually to re-run
# NO MATCH claims that initially got an incorrect response from the DQT API.
# DQT API has a limit of 300 requests/minute
# Task can be stopped by running `Delayed::Job.where("handler LIKE ?", "%QualificationsNoMatchCheckJob%").destroy_all`
# QualificationsNoMatchCheckJob.perform_later

class QualificationsNoMatchCheckJob < ApplicationJob
  def perform(filter: nil)
    claims = claims_with_no_match_qualification_tasks

    if filter == :qts_award_for_non_pg
      claims = claims.select do |claim|
        claim.notes.where("body LIKE ?", "%Qualification name: QTS Award\n%").any? &&
          (claim.eligibility.undergraduate_itt? || claim.eligibility.assessment_only?)
      end
    end

    claims.each_slice(250).with_index do |cl, index|
      sleep 60 unless index.zero?

      Task.where(claim_id: cl.pluck(:id), name: "qualifications").destroy_all

      cl.each do |claim|
        AutomatedChecks::ClaimVerifiers::Qualifications.new(
          claim: claim,
          dqt_teacher_status: Dqt::Client.new.teacher.find(
            claim.eligibility.teacher_reference_number,
            birthdate: claim.date_of_birth.to_s,
            nino: claim.national_insurance_number
          )
        ).perform
      end
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
    Policies::TargetedRetentionIncentivePayments.current_academic_year
  end
end
