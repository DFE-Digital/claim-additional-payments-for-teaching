module Journeys
  module FurtherEducationPayments
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[
        teaching-responsibilities
        further-education-provision-search
        select-provision
        contract-type
        fixed-term-contract
        taught-at-least-one-term
        teaching-hours-per-week
        teaching-hours-per-week-next-term
        further-education-teaching-start-year
        subjects-taught
        building-and-construction-courses
        chemistry-courses
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
        SLUGS.dup.tap do |sequence|
          if answers.contract_type == "permanent"
            sequence.delete("fixed-term-contract")
            sequence.delete("taught-at-least-one-term")
            sequence.delete("teaching-hours-per-week-next-term")
          end

          if answers.contract_type == "variable_hours"
            sequence.delete("fixed-term-contract")
          end

          if answers.fixed_term_full_year == true
            sequence.delete("taught-at-least-one-term")
          end

          if answers.subjects_taught.exclude?("building_construction")
            sequence.delete("building-and-construction-courses")
          end

          if answers.subjects_taught.exclude?("chemistry")
            sequence.delete("chemistry-courses")
          end
        end
      end
    end
  end
end
