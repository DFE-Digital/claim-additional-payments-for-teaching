module Journeys
  module EarlyYearsTeachers
    module Provider
      class SessionAnswers < Journeys::SessionAnswers
        # FIXME RL: remove this attribute once we've added the initial "real"
        # prototype screen
        attribute :favourite_colour, :string, pii: false
      end
    end
  end
end
