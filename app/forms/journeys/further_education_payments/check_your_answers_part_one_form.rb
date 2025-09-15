module Journeys
  module FurtherEducationPayments
    class CheckYourAnswersPartOneForm < Form
      def save
        journey_session
          .answers
          .assign_attributes(check_your_answers_part_one_completed: true)
        journey_session.save!
      end

      def completed?
        journey_session
          .answers
          .check_your_answers_part_one_completed
      end
    end
  end
end
