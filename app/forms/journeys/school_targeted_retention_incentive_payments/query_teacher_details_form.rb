module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class QueryTeacherDetailsForm < Form
      def save
        true
      end

      def redirect_to_next_slug?
        journey_session.answers.trs_national_insurance_number_completed_at.present?
      end

      def auto_refresh
        3
      end
    end
  end
end
