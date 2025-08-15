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
              "We can't find this claim"
            when "alternative_idv_already_completed"
              "Alternative IDV checks have already been completed for this claim"
            end
          end
        end
      end
    end
  end
end
