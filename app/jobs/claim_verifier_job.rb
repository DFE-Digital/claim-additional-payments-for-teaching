class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::ClaimVerifier.new(
      claim: claim,
      dqt_teacher_status: dqt_teacher_status(claim)
    ).perform
  end

  private

  def dqt_teacher_status(claim)
    return if claim.policy == Policies::EarlyYearsPayments

    if claim.has_dqt_record?
      Dqt::Teacher.new(claim.dqt_teacher_status)
    elsif claim.eligibility.teacher_reference_number.present?
      Dqt::Client.new.teacher.find(
        claim.eligibility.teacher_reference_number,
        include: "alerts,induction,routesToProfessionalStatuses"
      )
    end
  end
end
