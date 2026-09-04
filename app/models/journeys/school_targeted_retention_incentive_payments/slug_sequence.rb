module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "check-eligibility-intro",
        "hello"
      ]

      RESTRICTED_SLUGS = []

      DEAD_END_SLUGS = [
        "hello"
      ]

      SLUGS = ELIGIBILITY_SLUGS.freeze

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path(
          "targeted-retention-incentive-payments"
        )
      end

      def slugs
        [].tap do |sequence|
          sequence.push(*SLUGS)
        end
      end

      def journey
        Journeys::SchoolTargetedRetentionIncentivePayments
      end

      private
    end
  end
end
