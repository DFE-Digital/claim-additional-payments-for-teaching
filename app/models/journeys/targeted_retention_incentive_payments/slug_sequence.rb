module Journeys
  module TargetedRetentionIncentivePayments
    class SlugSequence
      # FIXME RL handle reset claim slug, handle eligibile later
      ELIGIBILITY_SLUGS = [
        "sign-in-or-continue",
        "current-school",
        "nqt-in-academic-year-after-itt",
        "supply-teacher",
        "entire-term-contract",
        "employed-directly",
        "poor-performance",
        "qualification",
        "itt-year",
        "eligible-itt-subject",
        "teaching-subject-now",
        "check-your-answers-part-one",
        "eligibility-confirmed"
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
        "mobile-verification"
      ]

      PAYMENT_DETAILS_SLUGS = [
        "personal-bank-account",
        "gender",
        "teacher-reference-number"
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
          sequence.push(*eligibility_slugs)
          sequence.push(*personal_details_slugs)
          sequence.push(*payment_details_slugs)
          sequence.push(*results_slugs)
        end
      end

      private

      def eligibility_slugs
        [].tap do |sequence|
          sequence << "sign-in-or-continue"
          sequence << "current-school"
          sequence << "nqt-in-academic-year-after-itt"
          sequence << "supply-teacher"
          sequence << "entire-term-contract" if answers.employed_as_supply_teacher?
          sequence << "employed-directly" if answers.employed_as_supply_teacher?
          sequence << "poor-performance"
          sequence << "qualification"
          sequence << "itt-year"
          sequence << "eligible-itt-subject"
          sequence << "teaching-subject-now"
          sequence << "check-your-answers-part-one"
          sequence << "eligibility-confirmed"
        end
      end

      def personal_details_slugs
        [].tap do |sequence|
          sequence << "information-provided"

          sequence << "personal-details"

          sequence << "postcode-search"
          sequence << "select-home-address" unless answers.skip_postcode_search?
          sequence << "address"

          sequence << "email-address" unless answers.email_address_check?
          sequence << "email-verification" unless answers.email_verified?

          sequence << "provide-mobile-number"
          sequence << "mobile-number" unless answers.provide_mobile_number == false
          sequence << "mobile-verification" unless answers.provide_mobile_number == false
        end
      end

      def payment_details_slugs
        [].tap do |sequence|
          sequence << "personal-bank-account"
          sequence << "gender"
          sequence << "teacher-reference-number"
        end
      end

      def results_slugs
        [].tap do |sequence|
          sequence << "check-your-answers"
        end
      end
    end
  end
end
