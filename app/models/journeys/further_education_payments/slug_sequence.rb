module Journeys
  module FurtherEducationPayments
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[
        teaching-responsibilities
        further-education-provision-search
        contract-type
        teaching-hours-per-week
        academic-year-in-further-education
        subject-areas
        building-and-construction-courses
        teaching-courses
        half-teaching-hours
        qualification
        poor-performance
      ]

      RESULTS_SLUGS = %w[
        check-your-answers
        ineligible
      ].freeze

      SLUGS = ELIGIBILITY_SLUGS + RESULTS_SLUGS

      def self.start_page_url
        if Rails.env.production?
          "https://www.example.com" # TODO: update to correct guidance
        else
          Rails.application.routes.url_helpers.landing_page_path("further-education-payments")
        end
      end

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        SLUGS
      end
    end
  end
end
