module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class IneligibleForm < Form
          def save
            true
          end
        end
      end
    end
  end
end
