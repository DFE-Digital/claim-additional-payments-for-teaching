module Journeys
  module EarlyYearsPayment
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        attribute :consent_given, :boolean

        def policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
