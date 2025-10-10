module Journeys
  module EarlyYearsPayment
    module Practitioner
      class ConfirmationForm < Journeys::ConfirmationForm
        def nursery_name
          submitted_claim.eligibility.eligible_ey_provider.nursery_name
        end
      end
    end
  end
end
