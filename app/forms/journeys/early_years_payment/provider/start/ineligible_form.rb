module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class IneligibleForm < Form
          def save
            true
          end
        end
      end
    end
  end
end
