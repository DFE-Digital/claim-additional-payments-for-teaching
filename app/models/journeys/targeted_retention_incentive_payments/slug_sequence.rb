module Journeys
  module TargetedRetentionIncentivePayments
    class SlugSequence
      # FIXME RL handle reset claim slug
      SLUGS = [
        "sign-in-or-continue",
        "current-school",
        "nqt-in-academic-year-after-itt",
        "supply-teacher",
        "poor-performance",
        "qualification",
        "itt-year"
      ]

      attr_reader :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path("targeted-retention-incentive-payments")
      end

      def slugs
        SLUGS
      end
    end
  end
end
