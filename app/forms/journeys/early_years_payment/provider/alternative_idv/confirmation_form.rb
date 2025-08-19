module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class ConfirmationForm < Form
          def completed?
            false
          end

          def claimant_name
            answers.claim.full_name
          end
        end
      end
    end
  end
end
