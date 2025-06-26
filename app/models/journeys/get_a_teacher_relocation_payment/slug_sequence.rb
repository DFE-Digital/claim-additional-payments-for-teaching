module Journeys
  module GetATeacherRelocationPayment
    class SlugSequence
      SLUGS = [
        "previous-payment-received",
        "application-route",
        "state-funded-secondary-school",
        "current-school",
        "headteacher-details",
        "contract-details",
        "start-date",
        "subject",
        "changed-workplace-or-new-contract",
        "breaks-in-employment",
        "visa",
        "entry-date",
        "check-your-answers-part-one",
        "information-provided",
        "nationality",
        "passport-number",
        "personal-details",
        "postcode-search",
        "select-home-address",
        "address",
        "email-address",
        "email-verification",
        "provide-mobile-number",
        "mobile-number",
        "mobile-verification",
        "personal-bank-account",
        "gender",
        "check-your-answers",
        "confirmation",
        "ineligible"
      ].freeze

      DEAD_END_SLUGS = [
        "ineligible"
      ].freeze

      RESTRICTED_SLUGS = [].freeze

      def self.start_page_url
        if Rails.env.production?
          "https://www.gov.uk/government/publications/international-relocation-payments/international-relocation-payments"
        else
          Rails.application.routes.url_helpers.landing_page_path("get-a-teacher-relocation-payment")
        end
      end

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        [].tap do |sequence|
          sequence.push(*eligibility_slugs)
          sequence.push(*personal_details_slugs)
          sequence.push(*payment_details_slugs)
          sequence.push(*results)
        end
      end

      def journey
        Journeys::GetATeacherRelocationPayment
      end

      private

      def eligibility_slugs
        [].tap do |slugs|
          slugs << "previous-payment-received"
          slugs << "application-route"
          slugs << "state-funded-secondary-school"
          slugs << "current-school"
          slugs << "headteacher-details"
          slugs << "contract-details"
          slugs << "start-date"
          slugs << "subject"
          slugs << "changed-workplace-or-new-contract"
          slugs << "breaks-in-employment"
          slugs << "visa"
          slugs << "entry-date"
          slugs << "check-your-answers-part-one"
        end
      end

      def personal_details_slugs
        [].tap do |slugs|
          slugs << "information-provided"
          slugs << "nationality"
          slugs << "passport-number"
          slugs << "personal-details"
          slugs << "postcode-search"
          slugs << "select-home-address" unless answers.skip_postcode_search? || answers.ordnance_survey_error?
          slugs << "address" unless address_set_by_postcode_search?
          slugs << "email-address"
          slugs << "email-verification" unless answers.email_verified?
          slugs << "provide-mobile-number"
          slugs << "mobile-number" unless answers.provide_mobile_number == false
          slugs << "mobile-verification" unless answers.provide_mobile_number == false || answers.mobile_verified?
        end
      end

      def payment_details_slugs
        [].tap do |slugs|
          slugs << "personal-bank-account"
          slugs << "gender"
        end
      end

      def results
        %w[
          check-your-answers
          confirmation
        ]
      end

      def address_set_by_postcode_search?
        answers.address_line_1.present? && answers.postcode.present?
      end
    end
  end
end
