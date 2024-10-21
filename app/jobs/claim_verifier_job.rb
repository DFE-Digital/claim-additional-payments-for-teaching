class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    if claim.eligibility.respond_to?(:teacher_reference_number)
      AutomatedChecks::ClaimVerifier.new(
        claim:,
        dqt_teacher_status: claim.has_dqt_record? ? Dqt::Teacher.new(claim.dqt_teacher_status) : Dqt::Client.new.teacher.find(
          claim.eligibility.teacher_reference_number,
          birthdate: claim.date_of_birth.to_s,
          nino: claim.national_insurance_number
        )
      ).perform
    end
  end
end
