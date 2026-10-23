module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class QueryTeacherDetailsForm < Form
      def self.skip_eligibility_check?
        true
      end

      def save
        true
      end

      def completed?
        journey_session.answers.trs_data_fetched_at.present?
      end

      def redirect_to_next_slug?
        journey_session.answers.trs_data_fetched_at.present?
      end

      def auto_refresh
        3
      end
    end
  end
end
