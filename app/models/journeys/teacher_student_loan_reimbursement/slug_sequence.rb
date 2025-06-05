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
      ELIGIBILITY_SLUGS = [
        "sign-in-or-continue",
        "reset-claim",
        "qualification-details",
        "qts-year",
        "select-claim-school",
        "claim-school",
        "claim-school-results",
        "subjects-taught",
        "still-teaching",
        "current-school",
        "leadership-position",
        "mostly-performed-leadership-duties",
        "eligibility-confirmed"
      ].freeze

      PERSONAL_DETAILS_SLUGS = [
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
        "mobile-verification"
      ].freeze

      PAYMENT_DETAILS_SLUGS = [
        "personal-bank-account",
        "gender",
        "teacher-reference-number"
      ].freeze

      RESULTS_SLUGS = [
        "check-your-answers",
        "ineligible"
      ].freeze

      DEAD_END_SLUGS = [
        "ineligible"
      ]

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      RESTRICTED_SLUGS = [].freeze

      attr_reader :journey_session

      delegate :answers, to: :journey_session

      def initialize(journey_session)
        @journey_session = journey_session
      end

      def slugs
        SLUGS.dup.tap do |sequence|
          if !Journeys::TeacherStudentLoanReimbursement.configuration.teacher_id_enabled?
            sequence.delete("sign-in-or-continue")
            sequence.delete("reset-claim")
            sequence.delete("qualification-details")
            sequence.delete("select-email")
            sequence.delete("select-mobile")
          end

          sequence.delete("claim-school-results") if answers.claim_school_id.present? && answers.provision_search.blank?

          sequence.delete("reset-claim") if skipped_dfe_sign_in? || answers.details_check?
          sequence.delete("current-school") if answers.employed_at_claim_school? || answers.employed_at_recent_tps_school?
          sequence.delete("mostly-performed-leadership-duties") unless answers.had_leadership_position?
          sequence.delete("mobile-number") if answers.provide_mobile_number == false
          sequence.delete("mobile-verification") if answers.provide_mobile_number == false
          sequence.delete("ineligible") unless ineligible?
          sequence.delete("personal-details") if answers.logged_in_with_tid? && personal_details_form.valid? && answers.all_personal_details_same_as_tid?
          sequence.delete("select-email") unless set_by_teacher_id?("email")
          if answers.logged_in_with_tid? && answers.email_address_check?
            sequence.delete("email-address")
            sequence.delete("email-verification")
          end

          if answers.email_verified == true
            sequence.delete("email-verification")
          end

          if set_by_teacher_id?("phone_number")
            sequence.delete("provide-mobile-number")
          else
            sequence.delete("select-mobile")
          end
          if answers.logged_in_with_tid? && (answers.mobile_check == "use" || answers.mobile_check == "declined")
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end
          unless answers.trn_from_tid? && answers.has_tps_school_for_student_loan_in_previous_financial_year?
            sequence.delete("select-claim-school")
          end
          sequence.delete("claim-school") if answers.claim_school_somewhere_else == false
          sequence.delete("teacher-reference-number") if answers.logged_in_with_tid? && answers.teacher_reference_number.present?

          if answers.logged_in_with_tid? && answers.details_check?
            if answers.qualifications_details_check
              sequence.delete("qts-year") if answers.dqt_teacher_record&.qts_award_date
            elsif signed_in_with_dfe_identity_and_details_match? && answers.has_no_dqt_data_for_claim?
              sequence.delete("qualification-details")
            end
          else
            sequence.delete("qualification-details")
          end

          if answers.ordnance_survey_error == true
            sequence.delete("select-home-address")
          end

          if answers.skip_postcode_search == true
            sequence.delete("select-home-address")
          end

          if answers.address_line_1.present? && answers.postcode.present?
            sequence.delete("address")
          end
        end
      end

      def self.start_page_url
        if Rails.env.production?
          "https://www.gov.uk/guidance/teachers-claim-back-your-student-loan-repayments"
        else
          "/student-loans/claim"
        end
      end

      private

      def personal_details_form
        PersonalDetailsForm.new(
          journey_session: journey_session,
          journey: Journeys::TeacherStudentLoanReimbursement,
          params: ActionController::Parameters.new
        )
      end

      def ineligible?
        eligibility_checker.ineligible?
      end

      def eligibility_checker
        @eligibility_checker ||= Policies::StudentLoans::PolicyEligibilityChecker.new(answers: answers)
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
