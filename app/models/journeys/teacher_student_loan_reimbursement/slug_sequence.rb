module Journeys
  module TeacherStudentLoanReimbursement
    # Determines the slugs that make up the claim process for a Student Loans
    # claim. Based on the existing answers on the claim, the sequence of slugs
    # will change. For example, if the claimant has said they are not paying off a
    # student loan, the questions to determine their loan plan will not be part of
    # the sequence.
    #
    # Note that the sequence is recalculated on each call to `slugs` so that it
    # accounts for any changes that may have been made to the claim and always
    # reflects the sequence based on the claim's current state.
    class SlugSequence
      SLUGS = [
        "sign-in-or-continue",
        "reset-claim",
        "qualification-details",
        "qts-year",
        "select-claim-school",
        "claim-school",
        "claim-school-results",
        "subjects-taught",
        "still-teaching",
        "still-teaching-tps",
        "current-school",
        "select-current-school",
        "leadership-position",
        "mostly-performed-leadership-duties",
        "eligibility-confirmed",
        "information-provided",
        "personal-details",
        "student-loan-amount",
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
        "personal-bank-account",
        "gender",
        "teacher-reference-number",
        "check-your-answers",
        "confirmation",
        "ineligible"
      ].freeze

      DEAD_END_SLUGS = [
        "confirmation",
        "ineligible"
      ]

      RESTRICTED_SLUGS = [].freeze

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
          sequence.push(*results_slugs)
        end
      end

      def self.start_page_url
        if Rails.env.production?
          "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments"
        else
          "/student-loans/claim"
        end
      end

      def journey
        Journeys::TeacherStudentLoanReimbursement
      end

      private

      def eligibility_slugs
        [].tap do |slugs|
          slugs << "sign-in-or-continue" if teacher_id_enabled?
          slugs << "reset-claim" if details_from_tid_did_not_match?
          # If they confirm their TID details, and we have DQT data for them
          # show it
          slugs << "qualification-details" if answers.details_check? && answers.has_dqt_data_for_claim?
          # We've got the qts-year from the confirmed dqt data, no need to ask
          # for it again.
          slugs << "qts-year" unless answers.qualifications_details_check? && answers.dqt_teacher_record&.qts_award_date
          # Show them the school we've found based on their tid info
          slugs << "select-claim-school" if answers.trn_from_tid? && answers.has_tps_school_for_student_loan_in_previous_financial_year?
          # Don't show the select school page if they confirmed the school
          # we found from tid data
          slugs << "claim-school" if answers.claim_school_somewhere_else != false

          slugs << "claim-school-results" if answers.claim_school_id.blank? || answers.provision_search.present?
          slugs << "subjects-taught"

          slugs << "still-teaching-tps" if answers.logged_in_with_tid_and_has_recent_tps_school?
          slugs << "still-teaching" unless answers.logged_in_with_tid_and_has_recent_tps_school?

          slugs << "current-school" unless answers.employed_at_claim_school? || answers.employed_at_recent_tps_school?
          slugs << "select-current-school" unless answers.employed_at_claim_school? || answers.employed_at_recent_tps_school?
          slugs << "leadership-position"
          slugs << "mostly-performed-leadership-duties" if answers.had_leadership_position?
          slugs << "eligibility-confirmed"
        end
      end

      def personal_details_slugs
        [].tap do |slugs|
          slugs << "information-provided"
          slugs << "personal-details" unless personal_details_from_tid_complete?
          slugs << "student-loan-amount"
          slugs << "postcode-search"
          slugs << "select-home-address" unless answers.ordnance_survey_error || answers.skip_postcode_search?
          slugs << "address" unless address_set_by_postcode_search?
          slugs << "select-email" if set_by_teacher_id?("email")
          slugs << "email-address" unless answers.email_address_check?
          slugs << "email-verification" unless answers.email_address_check? || answers.email_verified?
          slugs << "select-mobile" if set_by_teacher_id?("phone_number")
          slugs << "provide-mobile-number" unless set_by_teacher_id?("phone_number")
          slugs << "mobile-number" unless doesnt_want_to_provide_mobile_number? || use_mobile_number_from_tid?
          slugs << "mobile-verification" unless doesnt_want_to_provide_mobile_number? || use_mobile_number_from_tid?
        end
      end

      def payment_details_slugs
        [].tap do |slugs|
          slugs << "personal-bank-account"
          slugs << "gender"
          slugs << "teacher-reference-number" unless answers.trn_from_tid?
        end
      end

      def results_slugs
        ["check-your-answers", "confirmation"]
      end

      def details_from_tid_did_not_match?
        # even though they've logged in with TID logged_in_with_tid is false
        # unless they confirm their details. See SignInOrContinueForm
        answers.logged_in_with_tid == false && answers.details_check == false
      end

      def address_set_by_postcode_search?
        answers.address_line_1.present? && answers.postcode.present?
      end

      def personal_details_from_tid_complete?
        answers.logged_in_with_tid? &&
          personal_details_form.valid? &&
          answers.all_personal_details_same_as_tid?
      end

      def use_mobile_number_from_tid?
        answers.mobile_check == "use"
      end

      def doesnt_want_to_provide_mobile_number?
        answers.provide_mobile_number == false || answers.mobile_check == "declined"
      end

      def teacher_id_enabled?
        Journeys::TeacherStudentLoanReimbursement.configuration.teacher_id_enabled?
      end

      def personal_details_form
        PersonalDetailsForm.new(
          journey_session: journey_session,
          journey: Journeys::TeacherStudentLoanReimbursement,
          params: ActionController::Parameters.new
        )
      end

      def signed_in_with_dfe_identity_and_details_match?
        !!answers.dqt_teacher_status
      end

      def skipped_dfe_sign_in?
        !answers.logged_in_with_tid? && answers.details_check.nil?
      end

      def skipped_dfe_sign_in_or_details_did_not_match?
        answers.logged_in_with_tid == false
      end

      def set_by_teacher_id?(field)
        return false if skipped_dfe_sign_in_or_details_did_not_match?

        answers.teacher_id_user_info[field].present?
      end
    end
  end
end
