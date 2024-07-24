module Journeys
  module EarlyYearsPayment
    class SessionAnswers < Journeys::SessionAnswers
      def policy
        Policies::EarlyYearsPayment
      end
    end
  end
end
