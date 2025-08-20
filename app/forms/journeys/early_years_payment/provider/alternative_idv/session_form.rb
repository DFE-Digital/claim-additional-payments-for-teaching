module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SessionForm < ::Journeys::SessionForm
          attribute :alternative_idv_reference, :string
        end
      end
    end
  end
end
