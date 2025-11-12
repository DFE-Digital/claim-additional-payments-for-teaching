module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class ConfirmationForm < Journeys::ConfirmationForm
          def completed?
            false
          end

          def claimant_name
            submitted_claim.full_name
          end
        end
      end
    end
  end
end
