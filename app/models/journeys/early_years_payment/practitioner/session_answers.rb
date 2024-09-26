module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SessionAnswers < Journeys::SessionAnswers
        def policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
