module Journeys
  module EarlyYearsPayment
    module Practitioner
      class PersonalBankAccountForm < PersonalBankAccountForm
        def show_warning?
          false
        end
      end
    end
  end
end
