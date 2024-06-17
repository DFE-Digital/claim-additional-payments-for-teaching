module Journeys
  module GetATeacherRelocationPayment
    class SlugSequence
      ELIGIBILITY_SLUGS = %w[
        application-route
        contract-details
        employment-details
        entry-date
        school-details
        start-date
        subject
        trainee-details
        visa
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
      ].freeze

      PAYMENT_DETAILS_SLUGS = [
        "bank-or-building-society",
        "personal-bank-account",
        "building-society-account",
        "gender",
        "teacher-reference-number"
      ].freeze

      RESULTS_SLUGS = [
        "check-your-answers",
        "ineligible"
      ].freeze

      TEACHER_SPECIFIC_SLUGS = %w[
        school-details
        contract-details
      ]

      TRAINEE_SPECIFIC_SLUGS = %w[
        trainee-details
      ]

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
     )

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        SLUGS.dup.tap do |sequence|
          if answers.teacher_application?
            sequence.delete(*TRAINEE_SPECIFIC_SLUGS)
          else
            sequence.delete(*TEACHER_SPECIFIC_SLUGS)
          end
        end
      end
    end

    # FIXME RL: Double check what this should be
    def self.start_page_url
      if Rails.env.production?
        "https://www.gov.uk/government/publications/international-relocation-payments/international-relocation-payments"
      else
        Rails.application.routes.url_helpers.landing_page_path("get-a-teacher-relocation-payment")
      end
    end
  end
end

