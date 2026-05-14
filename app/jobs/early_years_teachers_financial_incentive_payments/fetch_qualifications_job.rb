require "csv"

module EarlyYearsTeachersFinancialIncentivePayments
  class FetchQualificationsJob < ApplicationJob
    def perform(journey_session)
      return if journey_session.answers.trs_data_fetched_at.present?

      client = Dqt::Client.new
      trs_data = client
        .teacher
        .find(journey_session.answers.teacher_auth_teacher_reference_number)

      journey_session.answers.assign_attributes(
        trs_data: trs_data.as_json(without_table: true),
        trs_data_fetched_at: Time.zone.now,
        has_eligible_qualification: trs_data.has_eligible_eytfi_qualification?
      )

      journey_session.save!
    end
  end
end
