class UpdateAdminClaimTasksWithDqtApiJob < ApplicationJob
  def perform(claim)
    AutomatedChecks::UpdateAdminClaimTasksWithDqt.new(
      claim: claim,
      dqt_teacher_statutes: Dqt::Client.new(
        host: Dqt.configuration.client.host
      ).api.qualified_teaching_status.show(
        params: {
          teacher_reference_number: claim.teacher_reference_number,
          national_insurance_number: claim.national_insurance_number
        }
      )
    ).perform
  end
end
