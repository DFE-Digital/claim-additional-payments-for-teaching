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
        ineligible
      ].freeze

      RESTRICTED_SLUGS = [].freeze

      DEAD_END_SLUGS = %w[]

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

        teaching_responsibilities_form = form_for_slug(SLUGS_HASH["teaching-responsibilities"])
        if teaching_responsibilities_form.completed_or_valid? && answers.teaching_responsibilities == true
          array << SLUGS_HASH["further-education-provision-search"]
        end

        fe_search_form = form_for_slug(SLUGS_HASH["further-education-provision-search"])
        if fe_search_form.completed_or_valid?
          array << SLUGS_HASH["select-provision"]
        end

        select_provision_form = form_for_slug(SLUGS_HASH["select-provision"])
        if select_provision_form.completed?
          array << SLUGS_HASH["contract-type"]
        end

        contract_type_form = form_for_slug(SLUGS_HASH["contract-type"])
        if contract_type_form.completed_or_valid?
          case answers.contract_type
          when "permanent"
            array << SLUGS_HASH["teaching-hours-per-week"]

            teaching_hours_per_week_form = form_for_slug(SLUGS_HASH["teaching-hours-per-week"])
            if select_provision_form.completed? && teaching_hours_per_week_form.completed_or_valid? && ["more_than_12", "between_2_5_and_12"].include?(answers.teaching_hours_per_week)
              array << SLUGS_HASH["further-education-teaching-start-year"]
            end
          when "fixed_term"
            array << SLUGS_HASH["fixed-term-contract"]

            fixed_term_contract_form = form_for_slug(SLUGS_HASH["fixed-term-contract"])
            if fixed_term_contract_form.completed_or_valid? && answers.fixed_term_full_year == true
              array << SLUGS_HASH["teaching-hours-per-week"]

              teaching_hours_per_week_form = form_for_slug(SLUGS_HASH["teaching-hours-per-week"])
              if select_provision_form.completed? && teaching_hours_per_week_form.completed_or_valid? && ["more_than_12", "between_2_5_and_12"].include?(answers.teaching_hours_per_week)
                array << SLUGS_HASH["teaching-hours-per-week-next-term"]

                teaching_hours_per_week_next_term_form = form_for_slug(SLUGS_HASH["teaching-hours-per-week-next-term"])
                if teaching_hours_per_week_next_term_form.completed_or_valid? && answers.teaching_hours_per_week_next_term == "at_least_2_5"
                  array << SLUGS_HASH["further-education-teaching-start-year"]
                end
              end
            end

            if fixed_term_contract_form.completed_or_valid? && answers.fixed_term_full_year == false
              array << SLUGS_HASH["taught-at-least-one-term"]

              taught_at_least_one_term_form = form_for_slug(SLUGS_HASH["taught-at-least-one-term"])
              if select_provision_form.completed? && taught_at_least_one_term_form.completed_or_valid? && answers.taught_at_least_one_term == true
                array << SLUGS_HASH["teaching-hours-per-week-next-term"]

                teaching_hours_per_week_next_term_form = form_for_slug(SLUGS_HASH["teaching-hours-per-week-next-term"])
                if teaching_hours_per_week_next_term_form.completed_or_valid? && answers.teaching_hours_per_week_next_term == "at_least_2_5"
                  array << SLUGS_HASH["further-education-teaching-start-year"]
                end
              end
            end
          when "variable_hours"
            array << SLUGS_HASH["taught-at-least-one-term"]

            taught_at_least_one_term_form = form_for_slug(SLUGS_HASH["taught-at-least-one-term"])

            if select_provision_form.completed? && taught_at_least_one_term_form.completed_or_valid? && answers.taught_at_least_one_term == true
              array << SLUGS_HASH["teaching-hours-per-week"]

              teaching_hours_per_week_form = form_for_slug(SLUGS_HASH["teaching-hours-per-week"])
              if select_provision_form.completed? && teaching_hours_per_week_form.completed_or_valid? && ["more_than_12", "between_2_5_and_12"].include?(answers.teaching_hours_per_week)
                array << SLUGS_HASH["teaching-hours-per-week-next-term"]

                teaching_hours_per_week_next_term_form = form_for_slug(SLUGS_HASH["teaching-hours-per-week-next-term"])
                if teaching_hours_per_week_next_term_form.completed_or_valid? && answers.teaching_hours_per_week_next_term == "at_least_2_5"
                  array << SLUGS_HASH["further-education-teaching-start-year"]
                end
              end
            end
          end
        end

        fe_teaching_start_year_form = form_for_slug(SLUGS_HASH["further-education-teaching-start-year"])
        if fe_teaching_start_year_form.completed_or_valid? && fe_teaching_start_year_form.eligible_start_year?
          array << SLUGS_HASH["subjects-taught"]
        end

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

        if answers.eligible_course_selected?
          array << SLUGS_HASH["hours-teaching-eligible-subjects"]
        end

        hours_teaching_eligible_subjects_form = form_for_slug(SLUGS_HASH["hours-teaching-eligible-subjects"])
        if hours_teaching_eligible_subjects_form.completed_or_valid? && answers.hours_teaching_eligible_subjects == true
          array << SLUGS_HASH["half-teaching-hours"]
        end

        half_teaching_hours_form = form_for_slug(SLUGS_HASH["half-teaching-hours"])
        if half_teaching_hours_form.completed_or_valid? && answers.half_teaching_hours == true
          array << SLUGS_HASH["teaching-qualification"]
        end

        teaching_qualification_form = form_for_slug(SLUGS_HASH["teaching-qualification"])
        if teaching_qualification_form.completed_or_valid? && !answers.lacks_teacher_qualification_or_enrolment?
          array << SLUGS_HASH["poor-performance"]
        end

        poor_performance_form = form_for_slug(SLUGS_HASH["poor-performance"])
        if poor_performance_form.completed_or_valid? && !answers.subject_to_problematic_actions?
          array << SLUGS_HASH["check-your-answers-part-one"]
          array << SLUGS_HASH["eligible"]
          array << SLUGS_HASH["sign-in"]
          array << SLUGS_HASH["information-provided"]
          array << SLUGS_HASH["personal-details"]
        end

        personal_details_form = form_for_slug(SLUGS_HASH["personal-details"])
        if personal_details_form.completed_or_valid?
          array << SLUGS_HASH["postcode-search"]
        end

        postcode_search_form = form_for_slug(SLUGS_HASH["postcode-search"])
        if answers.postcode.present? && postcode_search_form.completed_or_valid? && !answers.skip_postcode_search? && !answers.ordnance_survey_error
          array << SLUGS_HASH["select-home-address"]

          select_home_address_form = form_for_slug(SLUGS_HASH["select-home-address"])
          if select_home_address_form.completed_or_valid?
            array << if FeatureFlag.enabled?(:alternative_idv)
              SLUGS_HASH["passport"]
            else
              SLUGS_HASH["email-address"]
            end
          end
        end

        if answers.skip_postcode_search? || answers.ordnance_survey_error
          array << SLUGS_HASH["address"]

          address_form = form_for_slug(SLUGS_HASH["address"])
          if address_form.completed_or_valid?
            array << if FeatureFlag.enabled?(:alternative_idv)
              SLUGS_HASH["passport"]
            else
              SLUGS_HASH["email-address"]
            end
          end
        end

        if FeatureFlag.enabled?(:alternative_idv)
          passport_form = form_for_slug(SLUGS_HASH["passport"])

          if passport_form.completed_or_valid?
            array << SLUGS_HASH["email-address"]
          end
        end

        email_address_form = form_for_slug(SLUGS_HASH["email-address"])
        if email_address_form.completed_or_valid? && !answers.email_verified
          array << SLUGS_HASH["email-verification"]
        end

        if answers.email_verified
          array << SLUGS_HASH["provide-mobile-number"]
        end

        if answers.provide_mobile_number == true
          array << SLUGS_HASH["mobile-number"]
        end

        if answers.provide_mobile_number == true && !answers.mobile_verified
          array << SLUGS_HASH["mobile-verification"]
        end

        if answers.provide_mobile_number == true && answers.mobile_verified
          array << SLUGS_HASH["personal-bank-account"]
        end

        if answers.provide_mobile_number == false
          array << SLUGS_HASH["personal-bank-account"]
        end

        personal_bank_account_form = form_for_slug(SLUGS_HASH["personal-bank-account"])
        if personal_bank_account_form.completed_or_valid?
          array << SLUGS_HASH["gender"]
        end

        gender_form = form_for_slug(SLUGS_HASH["gender"])
        if gender_form.completed_or_valid?
          array << SLUGS_HASH["teacher-reference-number"]
        end

        trn_form = form_for_slug(SLUGS_HASH["teacher-reference-number"])
        if trn_form.completed_or_valid? && !answers.teacher_reference_number.nil?
          array << SLUGS_HASH["check-your-answers"]
        end

        # handle ineligibility
        if eligibility_checker.ineligible?
          array << SLUGS_HASH["ineligible"]
        end

        array
      end

      private

      def eligibility_checker
        @eligibility_checker ||= journey::EligibilityChecker.new(journey_session:)
      end

      def journey
        Journeys::FurtherEducationPayments
      end

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
