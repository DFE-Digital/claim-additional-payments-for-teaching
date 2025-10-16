module Journeys
  module TargetedRetentionIncentivePayments
    class ConfirmationForm < Journeys::ConfirmationForm
      def itt_academic_year
        submitted_claim.eligibility.itt_academic_year
      end
    end
  end
end
