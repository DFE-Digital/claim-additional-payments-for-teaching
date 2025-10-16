module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ConfirmationForm < Journeys::ConfirmationForm
          delegate(
            :reference,
            :first_name,
            :surname,
            :practitioner_email_address,
            to: :submitted_claim
          )
        end
      end
    end
  end
end
