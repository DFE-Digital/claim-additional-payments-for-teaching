module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[
        nursery-search
        nursery-select
        teaching-qualification-confirmation
        eligible-teaching-qualification-held
        sign-in
        eligible-qualification-confirmed
        confirm-eligibility
        accept-payment
        information-provided
      ].freeze

      RESTRICTED_SLUGS = [].freeze

      DEAD_END_SLUGS = %w[ineligible].freeze

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
        array << SLUGS_HASH["eligible-qualification-confirmed"]
        array << SLUGS_HASH["confirm-eligibility"]
        array << SLUGS_HASH["accept-payment"]
        array << SLUGS_HASH["information-provided"]

        array
      end

      def journey
        Journeys::EarlyYearsTeachersFinancialIncentivePayments
      end
    end
  end
end
