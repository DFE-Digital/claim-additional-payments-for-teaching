module Journeys
  module Reminders
    class SlugSequence
      SLUGS = [
        "personal-details",
        "email-verification",
        "confirmation"
      ].freeze

      DEAD_END_SLUGS = []

      def slugs
        SLUGS
      end

      class Navigator
        attr_reader :current_slug

        def initialize(current_slug:)
          @current_slug = current_slug
        end

        def next_slug
          SLUGS[current_index + 1]
        end

        def previous_slug
          return if current_index == 0

          SLUGS[current_index - 1]
        end

        private

        def current_index
          SLUGS.index(current_slug)
        end
      end
    end
  end
end
