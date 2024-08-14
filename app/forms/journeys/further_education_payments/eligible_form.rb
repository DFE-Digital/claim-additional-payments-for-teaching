module Journeys
  module FurtherEducationPayments
    class EligibleForm < Form
      def save
        journey_session.answers.assign_attributes(award_amount:)
        journey_session.save!
      end

      def award_amount
        journey_session.answers.calculate_award_amount
      end
    end
  end
end
