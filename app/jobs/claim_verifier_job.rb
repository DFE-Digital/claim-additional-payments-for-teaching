class ClaimVerifierJob < ApplicationJob
  def perform(claim)
    dqt_teacher_status = if claim.policy == Policies::EarlyYearsPayments
      nil
    elsif claim.has_dqt_record?
      Dqt::Teacher.new(claim.dqt_teacher_status)
    else
      Dqt::Client.new.teacher.find(
        claim.eligibility.teacher_reference_number,
        birthdate: claim.date_of_birth.to_s,
        nino: claim.national_insurance_number
      )
    end

    AutomatedChecks::ClaimVerifier.new(
      claim:,
      dqt_teacher_status:
    ).perform
  end
end
