module Journeys
  module EarlyYearsPayment
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        def policy
          Policies::EarlyYearsPayment
        end
      end
    end
  end
end
