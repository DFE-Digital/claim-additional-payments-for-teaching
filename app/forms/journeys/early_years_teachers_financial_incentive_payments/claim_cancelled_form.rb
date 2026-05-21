module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class ClaimCancelledForm < Form
      def save
        session.clear
      end
    end
  end
end
