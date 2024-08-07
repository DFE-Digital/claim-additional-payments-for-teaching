module Journeys
  module FurtherEducationPayments
    class EligibleForm < Form
      def save
        true
      end

      def award_amount
        journey_session.answers.award_amount
      end
    end
  end
end
