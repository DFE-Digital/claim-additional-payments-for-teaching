module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class SlugSequence
      SLUGS = %w[
        nursery-search
        teaching-qualification-confirmation
        eligible-teaching-qualification-held
        sign-in
        trn-found
      ].freeze

      SLUGS_HASH = SLUGS.to_h { |slug| [slug, slug] }.freeze

      RESTRICTED_SLUGS = [].freeze

      DEAD_END_SLUGS = [].freeze

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
        array << SLUGS_HASH["teaching-qualification-confirmation"]
        array << SLUGS_HASH["eligible-teaching-qualification-held"]
        array << SLUGS_HASH["sign-in"]
        array << SLUGS_HASH["trn-found"]

        array
      end

      def journey
        Journeys::EarlyYearsTeachersFinancialIncentivePayments
      end
    end
  end
end
