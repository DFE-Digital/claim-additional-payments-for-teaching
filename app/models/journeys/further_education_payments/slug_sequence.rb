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
        passport
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
        confirmation
        ineligible
      ].freeze

      RESTRICTED_SLUGS = [].freeze

      DEAD_END_SLUGS = %w[
        ineligible
      ]

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      SLUGS_HASH = SLUGS.to_h { |slug| [slug, slug] }.freeze

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path("further-education-payments")
      end

      def self.signed_out_path
        Rails.application.routes.url_helpers.landing_page_path("further-education-payments")
      end

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        array = []

        array << SLUGS_HASH["teaching-responsibilities"]
        array << SLUGS_HASH["further-education-provision-search"]
        array << SLUGS_HASH["select-provision"]
        array << SLUGS_HASH["contract-type"]

        case answers.contract_type
        when "permanent"
          array << SLUGS_HASH["teaching-hours-per-week"]
          array << SLUGS_HASH["further-education-teaching-start-year"]
        when "fixed_term"
          array << SLUGS_HASH["fixed-term-contract"]

          if answers.fixed_term_full_year == true
            array << SLUGS_HASH["teaching-hours-per-week"]
            array << SLUGS_HASH["teaching-hours-per-week-next-term"]
            array << SLUGS_HASH["further-education-teaching-start-year"]
          end

          if answers.fixed_term_full_year == false
            array << SLUGS_HASH["taught-at-least-one-term"]
            array << SLUGS_HASH["teaching-hours-per-week-next-term"]
            array << SLUGS_HASH["further-education-teaching-start-year"]
          end
        when "variable_hours"
          array << SLUGS_HASH["taught-at-least-one-term"]

          select_provision_form = form_for_slug(SLUGS_HASH["select-provision"])

          if select_provision_form.completed_or_valid? && answers.taught_at_least_one_term == true
            array << SLUGS_HASH["teaching-hours-per-week"]

            if select_provision_form.completed_or_valid? && ["more_than_12", "between_2_5_and_12"].include?(answers.teaching_hours_per_week)
              array << SLUGS_HASH["teaching-hours-per-week-next-term"]
              array << SLUGS_HASH["further-education-teaching-start-year"]
            end
          end
        end

        array << SLUGS_HASH["subjects-taught"]

        subjects_taught_form = form_for_slug(SLUGS_HASH["subjects-taught"])
        if subjects_taught_form.completed_or_valid?
          if answers.subjects_taught.include?("building_construction")
            array << SLUGS_HASH["building-construction-courses"]
          end

          if answers.subjects_taught.include?("chemistry")
            array << SLUGS_HASH["chemistry-courses"]
          end

          if answers.subjects_taught.include?("computing")
            array << SLUGS_HASH["computing-courses"]
          end

          if answers.subjects_taught.include?("early_years")
            array << SLUGS_HASH["early-years-courses"]
          end

          if answers.subjects_taught.include?("engineering_manufacturing")
            array << SLUGS_HASH["engineering-manufacturing-courses"]
          end

          if answers.subjects_taught.include?("maths")
            array << SLUGS_HASH["maths-courses"]
          end

          if answers.subjects_taught.include?("physics")
            array << SLUGS_HASH["physics-courses"]
          end
        end

        array << SLUGS_HASH["hours-teaching-eligible-subjects"]
        array << SLUGS_HASH["half-teaching-hours"]
        array << SLUGS_HASH["teaching-qualification"]
        array << SLUGS_HASH["poor-performance"]

        poor_performance_form = form_for_slug(SLUGS_HASH["poor-performance"])
        if poor_performance_form.completed_or_valid? && !answers.subject_to_problematic_actions?
          array << SLUGS_HASH["check-your-answers-part-one"]
          array << SLUGS_HASH["eligible"]
          array << SLUGS_HASH["sign-in"]
          array << SLUGS_HASH["information-provided"]
          array << SLUGS_HASH["personal-details"]
          array << SLUGS_HASH["postcode-search"]
        end

        postcode_search_form = form_for_slug(SLUGS_HASH["postcode-search"])
        if answers.postcode.present? && postcode_search_form.completed_or_valid? && !answers.skip_postcode_search? && !answers.ordnance_survey_error
          array << SLUGS_HASH["select-home-address"]
        end

        if answers.skip_postcode_search? || answers.ordnance_survey_error
          array << SLUGS_HASH["address"]
        end

        if FeatureFlag.enabled?(:alternative_idv)
          array << SLUGS_HASH["passport"]
        end

        array << SLUGS_HASH["email-address"]

        if !answers.email_verified
          array << SLUGS_HASH["email-verification"]
        end

        array << SLUGS_HASH["provide-mobile-number"]

        if answers.provide_mobile_number == true
          array << SLUGS_HASH["mobile-number"]
        end

        if answers.provide_mobile_number == true && !answers.mobile_verified
          array << SLUGS_HASH["mobile-verification"]
        end

        array << SLUGS_HASH["personal-bank-account"]
        array << SLUGS_HASH["gender"]
        array << SLUGS_HASH["teacher-reference-number"]
        array << SLUGS_HASH["check-your-answers"]
        array << SLUGS_HASH["confirmation"]

        array
      end

      def journey
        Journeys::FurtherEducationPayments
      end

      private

      def form_for_slug(slug)
        form_class = journey.form_class_for_slug(slug:)

        raise "Form not found for journey: #{journey} slug: #{slug}" if form_class.nil?

        form_class.new(
          journey:,
          journey_session:,
          params: ActionController::Parameters.new,
          session: {}
        )
      end
    end
  end
end
