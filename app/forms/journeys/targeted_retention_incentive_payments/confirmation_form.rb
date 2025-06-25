module Journeys
  module TargetedRetentionIncentivePayments
    class ConfirmationForm < Form
      delegate :reference, :email_address, to: :submitted_claim

      def itt_academic_year
        submitted_claim.eligibility.itt_academic_year
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
