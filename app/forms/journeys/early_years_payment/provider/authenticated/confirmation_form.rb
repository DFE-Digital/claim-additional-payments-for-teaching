module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ConfirmationForm < Form
          delegate(
            :reference,
            :first_name,
            :surname,
            :practitioner_email_address,
            to: :submitted_claim
          )

          private

          def submitted_claim
            @submitted_claim ||= Claim
              .by_policies_for_journey(journey)
              .find(session[:submitted_claim_id])
          end
        end
      end
    end
  end
end
