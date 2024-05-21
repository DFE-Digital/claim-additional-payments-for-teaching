module Journeys
  module AdditionalPaymentsForTeaching
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

      REMINDER_SLUGS = %w[
        personal-details
        email-verification
        set
      ].freeze

      SLUGS = (
        ELIGIBILITY_SLUGS +
        PERSONAL_DETAILS_SLUGS +
        PAYMENT_DETAILS_SLUGS +
        RESULTS_SLUGS
      ).freeze

      attr_reader :claim, :journey_session

      delegate :answers, to: :journey_session

      # Really this is a combined CurrentClaim
      def initialize(claim, journey_session)
        @claim = claim
        @journey_session = journey_session
      end

      # Even though we are inside the ECP namespace, this method can modify the
      # slug sequence of both LUP and ECP claims
      def slugs
        overall_eligibility_status = claim.eligibility_status
        lup_claim = claim.for_policy(Policies::LevellingUpPremiumPayments)
        ecp_claim = claim.for_policy(Policies::EarlyCareerPayments)

        SLUGS.dup.tap do |sequence|
          if !Journeys::AdditionalPaymentsForTeaching.configuration.teacher_id_enabled?
            sequence.delete("sign-in-or-continue")
            sequence.delete("reset-claim")
            sequence.delete("qualification-details")
            sequence.delete("correct-school")
            sequence.delete("select-email")
            sequence.delete("select-mobile")
          end

          sequence.delete("reset-claim") if skipped_dfe_sign_in? || answers.details_check?

          sequence.delete("select-email") unless set_by_teacher_id?("email")

          if claim.logged_in_with_tid? && claim.email_address_check
            sequence.delete("email-address")
            sequence.delete("email-verification")
          end

          if set_by_teacher_id?("phone_number")
            sequence.delete("provide-mobile-number")
          else
            sequence.delete("select-mobile")
          end

          if answers.logged_in_with_tid? && (claim.mobile_check == "use" || claim.mobile_check == "declined")
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

          sequence.delete("teacher-reference-number") if answers.logged_in_with_tid? && answers.teacher_reference_number.present?

          sequence.delete("correct-school") unless journey_session.logged_in_with_tid_and_has_recent_tps_school?
          sequence.delete("current-school") if claim.eligibility.school_somewhere_else == false

          if claim.provide_mobile_number == false
            sequence.delete("mobile-number")
            sequence.delete("mobile-verification")
          end

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

          sequence.delete("personal-details") if answers.logged_in_with_tid? && personal_details_form.valid? && answers.all_personal_details_same_as_tid?(claim)

          if answers.logged_in_with_tid? && answers.details_check?
            if claim.qualifications_details_check
              sequence.delete("qualification") if answers.ecp_dqt_teacher_record&.route_into_teaching
              sequence.delete("itt-year") if answers.ecp_dqt_teacher_record&.itt_academic_year_for_claim
              sequence.delete("eligible-itt-subject") if answers.ecp_dqt_teacher_record&.eligible_itt_subject_for_claim
              sequence.delete("eligible-degree-subject") if answers.lup_dqt_teacher_record&.eligible_degree_code?
            elsif signed_in_with_dfe_identity_and_details_match? && answers.has_no_dqt_data_for_claim?
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

      def personal_details_form
        PersonalDetailsForm.new(
          claim:,
          journey_session: journey_session,
          journey: Journeys::AdditionalPaymentsForTeaching,
          params: ActionController::Parameters.new
        )
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
        if answers.logged_in_with_tid?
          # If the DQT record confirms induction eligibility, the question is not required.
          return false if answers.ecp_dqt_teacher_record&.eligible_induction?
        end

        # In all other cases, the induction question is required.
        true
      end

      def ecp_school_selected?
        return false unless claim.eligibility.current_school

        Policies::EarlyCareerPayments::SchoolEligibility.new(claim.eligibility.current_school).eligible?
      end

      # We only retrieve dqt teacher status when the user is signed in with DfE
      # Sign-in and chosen that the details match. The previous implementation
      # relies on the presence of dqt_teacher_status to determine this.
      # TODO consider switching this to `answers.details_check`
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
