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
        "no-address-found",
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

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def slugs
        SLUGS.dup.tap do |sequence|
          if !Journeys.for_policy(claim.policy).configuration.teacher_id_enabled?
            sequence.delete("sign-in-or-continue")
            sequence.delete("reset-claim")
            sequence.delete("qualification-details")
            sequence.delete("select-email")
            sequence.delete("select-mobile")
          end

          sequence.delete("reset-claim") if (!claim.logged_in_with_tid? && claim.details_check.nil?) || claim.details_check?
          sequence.delete("current-school") if claim.eligibility.employed_at_claim_school? || claim.eligibility.employed_at_recent_tps_school?
          sequence.delete("mostly-performed-leadership-duties") unless claim.eligibility.had_leadership_position?
          sequence.delete("personal-bank-account") if claim.bank_or_building_society == "building_society"
          sequence.delete("building-society-account") if claim.bank_or_building_society == "personal_bank_account"
          sequence.delete("mobile-number") if claim.provide_mobile_number == false
          sequence.delete("mobile-verification") if claim.provide_mobile_number == false
          sequence.delete("ineligible") unless claim.eligibility&.ineligible?
          sequence.delete("personal-details") if claim.logged_in_with_tid? && personal_details_form.valid? && claim.all_personal_details_same_as_tid?
          sequence.delete("select-email") if (claim.logged_in_with_tid == false) || claim.teacher_id_user_info["email"].nil?
          if claim.logged_in_with_tid? && claim.email_address_check?
            sequence.delete("email-address")
            sequence.delete("email-verification")
          end

          if (claim.logged_in_with_tid == false) || claim.teacher_id_user_info["phone_number"].nil?
            sequence.delete("select-mobile")
          else
            sequence.delete("provide-mobile-number")
          end
          if claim.logged_in_with_tid? && (claim.mobile_check == "use" || claim.mobile_check == "declined")
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end
          unless claim.logged_in_with_tid? && claim.teacher_reference_number.present? && claim.has_tps_school_for_student_loan_in_previous_financial_year?
            sequence.delete("select-claim-school")
          end
          sequence.delete("claim-school") if claim.eligibility.claim_school_somewhere_else == false
          sequence.delete("teacher-reference-number") if claim.logged_in_with_tid? && claim.teacher_reference_number.present?

          if claim.logged_in_with_tid? && claim.details_check?
            if claim.qualifications_details_check
              sequence.delete("qts-year") if claim.dqt_teacher_record&.qts_award_date
            elsif claim.dqt_teacher_status && (!claim.has_dqt_record? || claim.has_no_dqt_data_for_claim?)
              sequence.delete("qualification-details")
            end
          else
            sequence.delete("qualification-details")
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
          claim:,
          journey: Journeys::TeacherStudentLoanReimbursement,
          params: ActionController::Parameters.new
        )
      end
    end
  end
end
