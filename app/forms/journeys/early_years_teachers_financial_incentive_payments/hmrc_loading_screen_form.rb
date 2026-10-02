module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class HmrcLoadingScreenForm < Form
      def save
        true
      end

      def completed?
        answers.hmrc_response_received?
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
