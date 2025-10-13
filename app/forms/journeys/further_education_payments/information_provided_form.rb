module Journeys
  module FurtherEducationPayments
    class InformationProvidedForm < Form
      def save
        journey_session.answers.assign_attributes(
          information_provided_completed: true
        )
        journey_session.save!
      end

      def completed?
        journey_session.answers.information_provided_completed
      end
    end
  end
end
