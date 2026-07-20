module Journeys
  module FurtherEducationPayments
    class InformationProvidedForm < Form
      def save
        journey_session.answers.update!(
          information_provided_completed: true
        )
      end

      def completed?
        journey_session.answers.information_provided_completed
      end
    end
  end
end
