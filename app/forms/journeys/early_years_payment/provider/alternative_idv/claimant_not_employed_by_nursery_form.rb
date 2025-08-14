module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class ClaimantNotEmployedByNurseryForm < Form
          def nursery_name
            answers.nursery.nursery_name
          end

          def completed?
            false
          end
        end
      end
    end
  end
end
