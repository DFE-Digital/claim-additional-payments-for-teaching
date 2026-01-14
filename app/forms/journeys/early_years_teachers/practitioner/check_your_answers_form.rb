module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class CheckYourAnswersForm < Form
        def save
          journey_session.answers.assign_attributes(
            check_your_answers_completed: true
          )
          journey_session.save!
        end

        def completed?
          answers.check_your_answers_completed?
        end
      end
    end
  end
end
