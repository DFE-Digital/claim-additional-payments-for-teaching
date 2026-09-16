module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class ConfirmationForm < Journeys::ConfirmationForm
      def save
        true
      end

      def itt_academic_year
        nil
      end
    end
  end
end
