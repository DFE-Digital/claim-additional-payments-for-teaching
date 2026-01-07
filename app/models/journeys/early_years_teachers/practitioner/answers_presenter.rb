module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class AnswersPresenter < BaseAnswersPresenter
        def eligibility_answers
          [
            ["Favourite colour", answers.favourite_colour, "favourite-colour"]
          ]
        end
      end
    end
  end
end
