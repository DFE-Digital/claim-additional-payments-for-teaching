module Journeys
  module FurtherEducationPayments
    class SlugSequence
      # TODO move sign-in to after the eligibility checks
      ELIGIBILITY_SLUGS = %w[
        sign-in
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
        building-construction-courses
        chemistry-courses
        computing-courses
        early-years-courses
        engineering-manufacturing-courses
        maths-courses
        physics-courses
        teaching-courses
        half-teaching-hours
        teaching-qualification
        poor-performance
        check-your-answers-part-one
        eligible
      ]

      PERSONAL_DETAILS_SLUGS = %w[
        one-login-placeholder
        information-provided
        personal-details
        postcode-search
        select-home-address
        address
        email-address
        email-verification
        provide-mobile-number
        mobile-number
        mobile-verification
      ].freeze

      PAYMENT_DETAILS_SLUGS = %w[
        bank-or-building-society
        personal-bank-account
        building-society-account
        gender
        teacher-reference-number
      ].freeze

      RESULTS_SLUGS = %w[
        check-your-answers
        ineligible
      ].freeze

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

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

          if answers.subjects_taught.exclude?("computing")
            sequence.delete("computing-courses")
          end

          if answers.subjects_taught.exclude?("early_years")
            sequence.delete("early-years-courses")
          end

          if answers.subjects_taught.exclude?("engineering_manufacturing")
            sequence.delete("engineering-manufacturing-courses")
          end

          if answers.subjects_taught.exclude?("maths")
            sequence.delete("maths-courses")
          end

          if answers.subjects_taught.exclude?("physics")
            sequence.delete("physics-courses")
          end

          if answers.provide_mobile_number == false
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end

          sequence.delete("personal-bank-account") if answers.building_society?
          sequence.delete("building-society-account") if answers.personal_bank_account?
        end
      end
    end
  end
end
