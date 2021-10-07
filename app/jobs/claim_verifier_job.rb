class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::ClaimVerifier.new(
      claim: claim,
      dqt_teacher_status: Dqt::Client.new.teacher.find(
        claim.teacher_reference_number,
        birthdate: claim.date_of_birth.to_s,
        nino: claim.national_insurance_number
      )
    ).perform
  end
end
