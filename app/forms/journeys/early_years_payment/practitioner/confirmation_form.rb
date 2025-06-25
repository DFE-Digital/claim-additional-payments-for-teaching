module Journeys
  module EarlyYearsPayment
    module Practitioner
      class ConfirmationForm < Form
        delegate :reference, :email_address, to: :submitted_claim

        def nursery_name
          submitted_claim.eligibility.eligible_ey_provider.nursery_name
        end

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
