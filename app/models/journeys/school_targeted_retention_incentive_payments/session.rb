module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class Session < Journeys::Session
      has_many_attached :employment_proofs

      attribute :answers, SessionAnswersType.new

      def journey_class
        Journeys::SchoolTargetedRetentionIncentivePayments
      end
    end
  end
end
