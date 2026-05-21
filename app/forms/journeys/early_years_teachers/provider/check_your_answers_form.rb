module Journeys
  module EarlyYearsTeachers
    module Provider
      class CheckYourAnswersForm < Form
        attribute :confirm_details_are_correct, :boolean

        def save
          journey_session.answers.assign_attributes(
            check_your_answers_form_completed: true
          )

          journey_session.save!
        end

        def completed?
          answers.check_your_answers_form_completed?
        end
      end
    end
  end
end
