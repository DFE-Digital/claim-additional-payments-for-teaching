require "csv"

module EarlyYearsTeachersFinancialIncentivePayments
  class FetchQualificationsBypassJob < ApplicationJob
    def perform(journey_session)
      return if journey_session.answers.trs_data_fetched_at.present?

      journey_session.answers.assign_attributes(
        trs_data: {},
        trs_data_fetched_at: Time.zone.now
      )

      journey_session.save!
    end
  end
end
