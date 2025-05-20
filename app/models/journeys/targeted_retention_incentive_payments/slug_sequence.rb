module Journeys
  module TargetedRetentionIncentivePayments
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "sign-in-or-continue",
        "reset-claim",
        "correct-school",
        "current-school",
        "nqt-in-academic-year-after-itt",
        "supply-teacher",
        "entire-term-contract",
        "employed-directly",
        "poor-performance",
        "qualification-details",
        "qualification",
        "itt-year",
        "eligible-itt-subject",
        "eligible-degree-subject",
        "teaching-subject-now",
        "check-your-answers-part-one",
        "eligibility-confirmed",
        "future-eligibility"
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
        "check-your-answers",
        "ineligible"
      ]

      RESTRICTED_SLUGS = []

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
          sequence.push(*initial_slugs)

          # For trainee teachers, we don't show any further slugs after
          # future-eligibility
          if answers.trainee_teacher?
            sequence.push(*trainne_teacher_slugs)
          else
            sequence.push(*eligibility_slugs)
            sequence.push(*personal_details_slugs)
            sequence.push(*payment_details_slugs)
            sequence.push(*results_slugs)
          end
        end
      end

      private

      def initial_slugs
        [].tap do |sequence|
          sequence << "sign-in-or-continue" if Journeys::TargetedRetentionIncentivePayments.configuration.teacher_id_enabled?
          sequence << "reset-claim" if answers.details_check == false
          sequence << "correct-school" if answers.logged_in_with_tid_and_has_recent_tps_school?
          sequence << "current-school" unless answers.chose_recent_tps_school?
          sequence << "nqt-in-academic-year-after-itt"
        end
      end

      def trainne_teacher_slugs
        [].tap do |sequence|
          sequence << "eligible-itt-subject"
          sequence << "eligible-degree-subject" if answers.eligible_itt_subject == "none_of_the_above"
          sequence << "future-eligibility"
        end
      end

      def eligibility_slugs
        [].tap do |sequence|
          sequence << "supply-teacher"
          sequence << "entire-term-contract" if answers.employed_as_supply_teacher?
          sequence << "employed-directly" if answers.employed_as_supply_teacher?
          sequence << "poor-performance"
          sequence << "qualification-details" if answers.dqt_record&.has_data_for_claim?
          sequence << "qualification" unless answers.dqt_qualification_confirmed?
          sequence << "itt-year" unless answers.dqt_itt_academic_year_confirmed?
          sequence << "eligible-itt-subject" unless answers.dqt_eligible_itt_subject_confirmed?
          sequence << "eligible-degree-subject" if answers.eligible_itt_subject == "none_of_the_above"
          sequence << "teaching-subject-now"
          sequence << "check-your-answers-part-one"
          sequence << "eligibility-confirmed"
        end
      end

      def personal_details_slugs
        [].tap do |sequence|
          sequence << "information-provided"

          sequence << "personal-details" unless answers.personal_details_set_by_tid?

          sequence << "postcode-search"
          sequence << "select-home-address" unless answers.skip_postcode_search? || answers.ordnance_survey_error?
          sequence << "address" if answers.skip_postcode_search? || answers.ordnance_survey_error?

          sequence << "select-email" if answers.set_by_teacher_id?("email")
          sequence << "email-address" unless answers.email_address_check?
          sequence << "email-verification" unless answers.email_verified?

          sequence << "select-mobile" if answers.set_by_teacher_id?("phone_number")
          sequence << "provide-mobile-number" unless answers.set_by_teacher_id?("phone_number")
          sequence << "mobile-number" unless answers.using_mobile_number_from_tid? || answers.doesnt_want_to_provide_mobile_number?
          sequence << "mobile-verification" unless answers.mobile_verified? || answers.using_mobile_number_from_tid? || answers.doesnt_want_to_provide_mobile_number?
        end
      end

      def payment_details_slugs
        [].tap do |sequence|
          sequence << "personal-bank-account"
          sequence << "gender"
          sequence << "teacher-reference-number" unless answers.set_by_teacher_id?("trn")
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
