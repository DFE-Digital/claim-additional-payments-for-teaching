module Journeys
  module FurtherEducationPayments
    class CheckYourAnswersPartOneForm < Form
      def save
        journey_session
          .answers
          .update!(check_your_answers_part_one_completed: true)
      end

      def completed?
        journey_session
          .answers
          .check_your_answers_part_one_completed
      end
    end
  end
end
