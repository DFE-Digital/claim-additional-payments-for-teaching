module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class QualificationsCheckForm < Form
      def save
        true
      end

      def redirect_to_next_slug?
        journey_session.answers.trs_data_fetched_at.present?
      end

      def auto_refresh
        1
      end
    end
  end
end
