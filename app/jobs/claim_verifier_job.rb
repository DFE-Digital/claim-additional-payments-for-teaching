class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::ClaimVerifier.new(
      claim: claim,
      dqt_teacher_status: dqt_teacher_status(claim)
    ).perform
  end

  private

  def dqt_teacher_status(claim)
    return unless claim.eligibility.respond_to?(:teacher_reference_number)

    if claim.has_dqt_record?
      Dqt::Teacher.new(claim.dqt_teacher_status)
    else
      Dqt::Client.new.teacher.find(
        claim.eligibility.teacher_reference_number,
        birthdate: claim.date_of_birth.to_s,
        nino: claim.national_insurance_number
      )
    end
  end
end
