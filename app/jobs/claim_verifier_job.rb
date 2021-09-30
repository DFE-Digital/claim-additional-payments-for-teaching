class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::ClaimVerifier.new(
      claim: claim,
      dqt_teacher_status: Fwy::Client.new.teacher.find(
        claim.teacher_reference_number,
        birthdate: claim.date_of_birth,
        nino: claim.national_insurance_number
      )
    ).perform
  end
end
