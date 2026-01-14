module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class PaymentNotAcceptedForm < Form
        def completed?
          false
        end
      end
    end
  end
end
