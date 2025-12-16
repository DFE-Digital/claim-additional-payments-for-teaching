module Journeys
  module EarlyYearsTeachers
    module Provider
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
