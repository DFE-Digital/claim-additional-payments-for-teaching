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
        building-construction-courses
        chemistry-courses
        computing-courses
        early-years-courses
        engineering-manufacturing-courses
        maths-courses
        physics-courses
        hours-teaching-eligible-subjects
        half-teaching-hours
        teaching-qualification
        poor-performance
        check-your-answers-part-one
        eligible
      ]

      PERSONAL_DETAILS_SLUGS = %w[
        sign-in
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
        personal-bank-account
        gender
        teacher-reference-number
      ].freeze

      RESULTS_SLUGS = %w[
        check-your-answers
        ineligible
      ].freeze

      RESTRICTED_SLUGS = [].freeze

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path("further-education-payments")
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
            sequence.delete("building-construction-courses")
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

          if answers.school_id.present?
            sequence.delete("select-provision")
          end

          if answers.email_verified == true
            sequence.delete("email-verification")
          end

          if answers.provide_mobile_number == false
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end

          if answers.mobile_verified == true
            sequence.delete("mobile-verification")
          end

          if answers.ordnance_survey_error == true
            sequence.delete("select-home-address")
          end

          if answers.skip_postcode_search == true
            sequence.delete("select-home-address")
          end

          if answers.address_line_1.present? && answers.postcode.present?
            sequence.delete("address")
          end

          if !eligibility_checker.ineligible?
            sequence.delete("ineligible")
          end

          if answers.performing_poorly?
            sequence.delete("check-your-answers-part-one")
            sequence.delete("eligible")
            sequence.delete("sign-in")
            sequence.delete("information-provided")
          end
        end
      end

      private

      def eligibility_checker
        @eligibility_checker ||= journey::EligibilityChecker.new(journey_session:)
      end

      def journey
        Journeys.for_routing_name(journey_session.journey)
      end
    end
  end
end
