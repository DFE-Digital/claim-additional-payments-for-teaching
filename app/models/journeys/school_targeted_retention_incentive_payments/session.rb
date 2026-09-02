module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class Session < Journeys::Session
      attribute :answers, SessionAnswersType.new

      def journey_class
        Journeys::SchoolTargetedRetentionIncentivePayments
      end
    end
  end
end
