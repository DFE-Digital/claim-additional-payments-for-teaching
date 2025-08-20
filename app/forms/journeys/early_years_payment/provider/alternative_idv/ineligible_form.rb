module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class IneligibleForm < Form
          def completed?
            false
          end

          def message
            case params[:ineligible_reason]
            when "claim_not_found"
              "We can’t find this claim"
            when "alternative_idv_already_completed"
              "An employment check has already been completed for this claim"
            end
          end
        end
      end
    end
  end
end
