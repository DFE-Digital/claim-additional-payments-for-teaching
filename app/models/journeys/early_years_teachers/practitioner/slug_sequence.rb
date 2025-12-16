module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class SlugSequence
        SLUGS = %w[
          favourite-colour
          check-your-answers
        ].freeze

        RESTRICTED_SLUGS = %w[].freeze

        DEAD_END_SLUGS = %w[].freeze

        def initialize(journey_session)
          @journey_session = journey_session
        end

        def slugs
          array = []

          array << "favourite-colour"
          array << "check-your-answers"

          array
        end
      end
    end
  end
end
