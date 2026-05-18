module Journeys
  module EarlyYearsTeachers
    module Provider
      class SlugSequence
        SLUGS = %w[
          provider-email
          check-your-email
          check-nursery-details
          update-nursery-details
          employer-paye-reference
          organisation-email-address
          provide-teacher-details
          performance-and-discipline
          teacher-not-eligible
          manage-teachers
          check-your-answers
          confirmation
        ].freeze

        RESTRICTED_SLUGS = %w[].freeze

        DEAD_END_SLUGS = %w[
          provide-teacher-details
          performance-and-discipline
          teacher-not-eligible
          confirmation
        ].freeze

        attr_reader :journey_session

        def initialize(journey_session)
          @journey_session = journey_session
        end

        delegate :answers, to: :journey_session

        def slugs
          array = []

          array << "provider-email"
          array << "check-your-email"
          array << "check-nursery-details"

          if answers.nursery_details_confirmed == false
            array << "update-nursery-details"
          end

          array << "employer-paye-reference"

          array << "organisation-email-address"

          array << "provide-teacher-details"

          if answers.current_teacher&.performance_and_discipline_incomplete?
            array << "performance-and-discipline"
          end

          if answers.current_teacher&.performance_or_discipline
            array << "teacher-not-eligible"
          end

          array << "manage-teachers"

          array << "check-your-answers"

          array << "confirmation"

          array
        end
      end
    end
  end
end
