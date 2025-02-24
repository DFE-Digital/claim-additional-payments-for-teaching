module Journeys
  module TargetedRetentionIncentivePayments
    class SlugSequence
      # FIXME RL handle reset claim slug, handle eligibile later
      ELIGIBILITY_SLUGS = [
        "sign-in-or-continue",
        "current-school",
        "nqt-in-academic-year-after-itt",
        "supply-teacher",
        "poor-performance",
        "qualification",
        "itt-year",
        "eligible-itt-subject",
        "teaching-subject-now",
        "check-your-answers-part-one",
        "eligibility-confirmed",
      ]

      PERSONAL_DETAILS_SLUGS = [
        "information-provided",
        "personal-details",
        "postcode-search",
        "select-home-address",
        "address",
        "select-email",
        "email-address",
        "email-verification",
        "select-mobile",
        "provide-mobile-number",
        "mobile-number",
        "mobile-verification",
      ]

      PAYMENT_DETAILS_SLUGS = [
        "personal-bank-account",
        "gender",
        "teacher-reference-number",
      ]

      RESULTS_SLUGS = [
        "check-your-answers"
      ]

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

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
