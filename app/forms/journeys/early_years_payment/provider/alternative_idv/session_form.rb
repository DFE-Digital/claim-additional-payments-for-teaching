module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SessionForm < ::Journeys::SessionForm
          attribute :claim_reference, :string
        end
      end
    end
  end
end
