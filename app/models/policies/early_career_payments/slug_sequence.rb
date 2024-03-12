module Policies
  module EarlyCareerPayments
    # Determines the slugs that make up the claim process for a Early-Career Payments
    # claim. Based on the existing answers on the claim, the sequence of slugs
    # will change. For example, if the claimant has said they are not a supply teacher
    # then they will not answer the two questions that are associated with supply
    # teaching. 'entire-term-contract' and 'employed-directly' will not be part of the sequence.
    #
    # Note that the sequence is recalculated on each call to `slugs` so that it
    # accounts for any changes that may have been made to the claim and always
    # reflects the sequence based on the claim's current state.
    # There are 4 distinct phases of the claimant journey
    class SlugSequence
      ELIGIBILITY_SLUGS = [
        "sign-in-or-continue",
        "teacher-detail",
        "reset-claim",
        "correct-school",
        "current-school",
        "nqt-in-academic-year-after-itt",
        "induction-completed",
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
        "eligible-later",
        "future-eligibility"
      ].freeze

      PERSONAL_DETAILS_SLUGS = [
        "information-provided",
        "personal-details",
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

      STUDENT_LOANS_SLUGS = [
        "student-loan",
        "student-loan-country",
        "student-loan-how-many-courses",
        "student-loan-start-date",
        "masters-doctoral-loan",
        "masters-loan",
        "doctoral-loan"
      ].freeze

      RESULTS_SLUGS = [
        "check-your-answers",
        "ineligible"
      ].freeze

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        STUDENT_LOANS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      attr_reader :claim

      # Really this is a combined CurrentClaim
      def initialize(claim)
        @claim = claim
      end

      # Even though we are inside the ECP namespace, this method can modify the
      # slug sequence of both LUP and ECP claims
      def slugs
        overall_eligibility_status = claim.eligibility_status
        lup_claim = claim.for_policy(LevellingUpPremiumPayments)
        ecp_claim = claim.for_policy(Policies::EarlyCareerPayments)

        SLUGS.dup.tap do |sequence|
          if !JourneyConfiguration.for(claim.policy).teacher_id_enabled?
            sequence.delete("sign-in-or-continue")
            sequence.delete("teacher-detail")
            sequence.delete("reset-claim")
            sequence.delete("qualification-details")
            sequence.delete("correct-school")
            sequence.delete("select-email")
            sequence.delete("select-mobile")
          end

          sequence.delete("teacher-detail") unless claim.logged_in_with_tid?
          sequence.delete("reset-claim") if (!claim.logged_in_with_tid? && claim.details_check.nil?) || claim.details_check?

          sequence.delete("select-email") if (claim.logged_in_with_tid == false) || claim.teacher_id_user_info["email"].nil?
          if claim.logged_in_with_tid? && claim.email_address_check
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

          unless claim.eligibility.employed_as_supply_teacher?
            sequence.delete("entire-term-contract")
            sequence.delete("employed-directly")
          end

          sequence.delete("eligibility-confirmed") unless overall_eligibility_status == :eligible_now
          sequence.delete("eligible-later") unless overall_eligibility_status == :eligible_later

          sequence.delete("personal-bank-account") if claim.bank_or_building_society == "building_society"
          sequence.delete("building-society-account") if claim.bank_or_building_society == "personal_bank_account"

          sequence.delete("teacher-reference-number") if claim.logged_in_with_tid? && claim.teacher_reference_number.present?

          sequence.delete("correct-school") unless claim.logged_in_with_tid_and_has_recent_tps_school?
          sequence.delete("current-school") if claim.eligibility.school_somewhere_else == false

          if claim.provide_mobile_number == false
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end

          remove_student_loan_slugs(sequence) if claim.no_student_loan?
          sequence.delete("masters-doctoral-loan") if claim.has_student_loan?
          remove_masters_doctoral_loan_slugs(sequence) if claim.has_masters_doctoral_loan == false
          remove_student_loan_country_slugs(sequence)

          if claim.eligibility.trainee_teacher?
            trainee_teacher_slugs(sequence)
            sequence.delete("eligible-degree-subject") unless lup_claim&.eligibility&.indicated_ineligible_itt_subject?
          else
            sequence.delete("ineligible") unless [:ineligible, :eligible_later].include?(overall_eligibility_status)
            sequence.delete("future-eligibility")
            sequence.delete("eligible-degree-subject") unless ecp_claim&.eligibility&.status == :ineligible && lup_claim&.eligibility&.indicated_ineligible_itt_subject?
          end

          sequence.delete("induction-completed") unless induction_question_required?

          if ecp_claim.eligibility.induction_not_completed? && ecp_claim.eligibility.ecp_only_school?
            replace_ecp_only_induction_not_completed_slugs(sequence)
          end

          sequence.delete("personal-details") if claim.logged_in_with_tid? && claim.has_all_valid_personal_details?

          if claim.logged_in_with_tid? && claim.details_check?
            if claim.qualifications_details_check
              sequence.delete("qualification") if claim.dqt_teacher_record&.route_into_teaching
              sequence.delete("itt-year") if claim.dqt_teacher_record&.itt_academic_year_for_claim
              sequence.delete("eligible-itt-subject") if claim.dqt_teacher_record&.eligible_itt_subject_for_claim
              sequence.delete("eligible-degree-subject") if claim.for_policy(LevellingUpPremiumPayments)&.dqt_teacher_record&.eligible_degree_code?
            elsif claim.dqt_teacher_status && (!claim.has_dqt_record? || claim.has_no_dqt_data_for_claim?)
              sequence.delete("qualification-details")
            end
          else
            sequence.delete("qualification-details")
          end
        end
      end

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path("additional-payments")
      end

      private

      def remove_student_loan_slugs(sequence, slugs = nil)
        slugs ||= %w[
          student-loan-country
          student-loan-how-many-courses
          student-loan-start-date
        ]

        slugs.each { |slug| sequence.delete(slug) }
      end

      def remove_masters_doctoral_loan_slugs(sequence, slugs = nil)
        slugs ||= %w[
          masters-loan
          doctoral-loan
        ]

        slugs.each { |slug| sequence.delete(slug) }
      end

      def remove_student_loan_country_slugs(sequence)
        slugs = %w[
          student-loan-how-many-courses
          student-loan-start-date
        ]

        if [
          StudentLoan::NORTHERN_IRELAND,
          StudentLoan::SCOTLAND
        ].include?(claim.student_loan_country)
          remove_student_loan_slugs(sequence, slugs)
        end
      end

      def replace_ecp_only_induction_not_completed_slugs(sequence)
        slugs = %w[
          current-school
          nqt-in-academic-year-after-itt
          induction-completed
          eligible-later
        ]

        sequence.replace(slugs)
      end

      # This method swaps out the entire slug sequence and replaces it with this tiny
      # journey.
      def trainee_teacher_slugs(sequence)
        trainee_slugs = %w[
          current-school
          nqt-in-academic-year-after-itt
          eligible-itt-subject
          eligible-degree-subject
          future-eligibility
          ineligible
        ]

        [sequence.dup - trainee_slugs].flatten.each { |slug| sequence.delete(slug) }
      end

      def induction_question_required?
        # Induction question is not required if an ECP-eligible school is not selected.
        return false unless ecp_school_selected?

        # If the claimant is logged in with their Teacher ID, check the DQT record directly.
        if claim.logged_in_with_tid?
          # If the DQT record confirms induction eligibility, the question is not required.
          return false if claim.for_policy(Policies::EarlyCareerPayments).dqt_teacher_record&.eligible_induction?
        end

        # In all other cases, the induction question is required.
        true
      end

      def ecp_school_selected?
        return false unless claim.eligibility.current_school

        Policies::EarlyCareerPayments::SchoolEligibility.new(claim.eligibility.current_school).eligible?
      end
    end
  end
end
