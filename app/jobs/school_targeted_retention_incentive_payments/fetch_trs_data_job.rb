module SchoolTargetedRetentionIncentivePayments
  class FetchTrsDataJob < ApplicationJob
    def perform(journey_session:)
      return if journey_session.answers.trs_data_fetched_at.present?

      client = Dqt::Client.new

      trs_data = client
        .teacher
        .find(
          journey_session.answers.teacher_auth_teacher_reference_number,
          include: "alerts,induction,routesToProfessionalStatuses"
        )

      journey_session.answers.update!(
        trs_data: trs_data.as_json(without_table: true) || {},
        trs_data_fetched_at: Time.zone.now
      )
    end
  end
end
