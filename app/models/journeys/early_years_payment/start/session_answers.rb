module Journeys
  module EarlyYearsPayment
    module Start
      class SessionAnswers < Journeys::SessionAnswers
        def policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
