module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class HmrcLoadingScreenForm < Form
      def save
        true
      end

      def completed?
        answers.hmrc_api_job_completed?
      end

      def redirect_to_next_slug?
        completed?
      end

      def auto_refresh
        5
      end
    end
  end
end
