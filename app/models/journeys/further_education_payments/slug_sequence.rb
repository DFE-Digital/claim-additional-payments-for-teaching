module Journeys
  module FurtherEducationPayments
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[
        teaching-responsibilities
        further-education-provision-search
        select-provision
        contract-type
        teaching-hours-per-week
        further-education-teaching-start-year
        subjects-taught
        building-and-construction-courses
        teaching-courses
        half-teaching-hours
        teaching-qualification
        poor-performance
        check-your-answers-part-one
      ]

      RESULTS_SLUGS = %w[
        check-your-answers
        eligible
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
