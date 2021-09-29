class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::ClaimVerifier.new(
      claim: claim,
      dqt_teacher_statuses: Dqt::Client.new.api.qualified_teaching_statuses.show(
        params: {
          teacher_reference_number: claim.teacher_reference_number,
          national_insurance_number: claim.national_insurance_number
        }
      )
    ).perform
  end
end
