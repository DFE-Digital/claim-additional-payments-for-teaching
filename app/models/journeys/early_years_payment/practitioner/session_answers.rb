module Journeys
  module EarlyYearsPayment
    module Practitioner
      class SessionAnswers < Journeys::SessionAnswers
        attribute :reference_number, :string
        attribute :start_email, :string

        def policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
