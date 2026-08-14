class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::ClaimVerifier.new(
      claim: claim,
      dqt_teacher_status: dqt_teacher_status(claim)
    ).perform
  end

  private

  def dqt_teacher_status(claim)
    return if claim.policy.in?([
      Policies::EarlyYearsPayments,
      Policies::EarlyYearsTeachersFinancialIncentivePayments
    ])

    if !claim.has_dqt_record? && claim.eligibility.teacher_reference_number.present?
      dqt_teacher_status = Dqt::Client.new.teacher.find_raw(
        claim.eligibility.teacher_reference_number,
        include: "alerts,induction,routesToProfessionalStatuses"
      )

      claim.update!(dqt_teacher_status: dqt_teacher_status)
    end

    Dqt::Teacher.new(claim.dqt_teacher_status)
  end
end
