module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "current-school",
        "select-current-school",
        "half-contracted-hours",
        "sign-in",
        "existing-claim",
        "existing-claims",
        "query-teacher-details",
        "verify-national-insurance-number",
        "national-insurance-number",
        "teacher-details",
        "maybe-eligible",
        "information-provided",
        "postcode-search",
        "select-home-address",
        "address",
        "personal-bank-account",
        "gender",
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

        if show_existing_claim?
          array << "existing-claim"
          array << "existing-claims"
        else
          array << "query-teacher-details"

          array << "verify-national-insurance-number" if show_verify_national_insurance_number?
          array << "national-insurance-number" if show_national_insurance_number?
          array << "teacher-details"
          array << "maybe-eligible"
          array << "information-provided"
          array << "postcode-search"

          array << if answers.postcode_searched?
            "select-home-address"
          else
            "address"
          end

          array << "personal-bank-account"
          array << "gender"
          array << "check-your-answers"
          array << "confirmation"
        end
      end

      def journey
        Journeys::SchoolTargetedRetentionIncentivePayments
      end

      private

      def show_existing_claim?
        return false if answers.payroll_gender.present?

        OneLoginAccount
          .new(uid: answers.teacher_auth_one_login_uid)
          .claims
          .where(policy: Policies::TargetedRetentionIncentivePayments)
          .where(academic_year: journey.configuration.current_academic_year)
          .exists?
      end

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
