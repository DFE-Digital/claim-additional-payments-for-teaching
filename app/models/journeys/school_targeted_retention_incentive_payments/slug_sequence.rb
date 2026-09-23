module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "current-school",
        "select-current-school",
        "half-contracted-hours",
        "sign-in",
        "query-teacher-details",
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
        array << "query-teacher-details"

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
        journey_session.answers.trs_data_fetched_at.present?
          && journey_session.answers.trs_data["nationalInsuranceNumber"].present?
      end

      def show_national_insurance_number?
        journey_session.answers.trs_data_fetched_at.present?
          && journey_session.answers.trs_data["nationalInsuranceNumber"].blank?
      end
    end
  end
end
