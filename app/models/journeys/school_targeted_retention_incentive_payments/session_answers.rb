module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :award_amount, :decimal, pii: false

      def policy
        Policies::TargetedRetentionIncentivePayments
      end
    end
  end
end
