module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "current-school",
        "select-current-school",
        "half-contracted-hours",
        "sign-in",
        "query-national-insurance-number",
        "verify-national-insurance-number",
        "national-insurance-number",
        "teacher-details",
        "hello",
        "check-your-answers",
        "confirmation"
      ]

      RESTRICTED_SLUGS = []

      DEAD_END_SLUGS = [
        "ineligible",
        "confirmation"
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
        array = []

        array << "current-school"
        array << "select-current-school"
        array << "half-contracted-hours"
        array << "sign-in"
        array << "query-national-insurance-number"

        array << "verify-national-insurance-number" if show_verify_national_insurance_number?
        array << "national-insurance-number" if show_national_insurance_number?
        array << "teacher-details"
        array << "hello"
        array << "check-your-answers"
        array << "confirmation"
      end

      def journey
        Journeys::SchoolTargetedRetentionIncentivePayments
      end

      private

      def show_verify_national_insurance_number?
        journey_session.answers.trs_national_insurance_number_completed_at.present?
          && journey_session.answers.trs_national_insurance_number.present?
      end

      def show_national_insurance_number?
        journey_session.answers.trs_national_insurance_number_completed_at.present?
          && journey_session.answers.trs_national_insurance_number.blank?
      end
    end
  end
end
