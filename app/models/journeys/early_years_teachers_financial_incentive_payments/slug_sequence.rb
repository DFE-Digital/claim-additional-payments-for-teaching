module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[
        nursery-search
        nursery-select
        teaching-qualification-confirmation
        eligible-teaching-qualification-held
        sign-in
        qualifications-check
        continue-claim
        claim-cancelled
        upload-employment-proof
        review-employment-proof
        uploaded-employment-proof
        delete-employment-proof
        upload-employment-proof-success
        information-provided
        postcode-search
        select-home-address
        address
        gender
        national-insurance-number
        personal-bank-account
        check-your-answers
        confirmation
        ineligible
      ].freeze

      DEAD_END_SLUGS = %w[
        ineligible
        claim-cancelled
        confirmation
      ].freeze

      RESTRICTED_SLUGS = [].freeze

      SLUGS = (ELIGIBILITY_SLUGS + RESTRICTED_SLUGS + DEAD_END_SLUGS).freeze

      SLUGS_HASH = SLUGS.to_h { |slug| [slug, slug] }.freeze

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path("early-years-teachers-financial-incentive-payments")
      end

      def self.signed_out_path
        Rails.application.routes.url_helpers.landing_page_path("early-years-teachers-financial-incentive-payments")
      end

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        array = []

        array << SLUGS_HASH["nursery-search"]

        if answers.nursery_id.blank?
          array << SLUGS_HASH["nursery-select"]
        end

        array << SLUGS_HASH["teaching-qualification-confirmation"]
        array << SLUGS_HASH["eligible-teaching-qualification-held"]
        array << SLUGS_HASH["sign-in"]
        array << SLUGS_HASH["qualifications-check"]
        array << SLUGS_HASH["continue-claim"]

        if answers.continue_claim == false
          array << SLUGS_HASH["claim-cancelled"]
        end

        array << SLUGS_HASH["upload-employment-proof"]
        array << SLUGS_HASH["review-employment-proof"]
        array << SLUGS_HASH["uploaded-employment-proof"]
        array << SLUGS_HASH["delete-employment-proof"]
        array << SLUGS_HASH["upload-employment-proof-success"]
        array << SLUGS_HASH["information-provided"]
        array << SLUGS_HASH["postcode-search"]

        postcode_search_form = form_for_slug(SLUGS_HASH["postcode-search"])
        if answers.postcode.present? && postcode_search_form.completed_or_valid? && !answers.skip_postcode_search? && !answers.ordnance_survey_error
          array << SLUGS_HASH["select-home-address"]
        end

        array << SLUGS_HASH["address"]
        array << SLUGS_HASH["gender"]
        array << SLUGS_HASH["national-insurance-number"]
        array << SLUGS_HASH["personal-bank-account"]
        array << SLUGS_HASH["check-your-answers"]
        array << SLUGS_HASH["confirmation"]

        array
      end

      def journey
        Journeys::EarlyYearsTeachersFinancialIncentivePayments
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
