module Journeys
  module EarlyYearsPayment
    module Practitioner
      class IneligibleForm < Form
        def save
          true
        end
      end
    end
  end
end
