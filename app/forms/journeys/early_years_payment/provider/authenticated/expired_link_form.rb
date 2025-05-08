module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ExpiredLinkForm < Form
          def save
            true
          end
        end
      end
    end
  end
end
