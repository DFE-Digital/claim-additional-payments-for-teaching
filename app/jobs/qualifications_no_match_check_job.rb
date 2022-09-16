# This job is not called anywhere in the code but can be used manually to re-run
# NO MATCH claims that initially got an incorrect response from the DQT API.
# QualificationsCheckJob.perform_later

class QualificationsNoMatchCheckJob < ApplicationJob
  def perform
    no_match_claims = claims_with_no_match_qualification_tasks

    no_match_claims.each_slice(300) do |claims|
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
    end
  end

  private

  def claims_with_no_match_qualification_tasks
    Claim.joins(:tasks).where(tasks: {name: "qualifications", claim_verifier_match: :none, manual: false})
  end
end
