module Journeys
  module EarlyYearsPayment
    module Practitioner
      class BankDetailsForm < BankDetailsForm
        def show_warning?
          false
        end
      end
    end
  end
end
