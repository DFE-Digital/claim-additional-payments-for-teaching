# FIXME RL: remove this form once we've added the initial "real" prototype
# screen
module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class FavouriteColourForm < Form
        attribute :favourite_colour, :string

        def save
          return false unless valid?

          journey_session.answers.assign_attributes(
            favourite_colour: favourite_colour
          )

          journey_session.save!
        end
      end
    end
  end
end
