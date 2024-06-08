module Journeys
  module AdditionalPaymentsForTeaching
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper
      include AdditionalPaymentsHelper
      include Claims::IttSubjectHelper

      def eligibility
        @eligibility ||= claim_submission_form.eligible_now_or_later.first
      end

      # Formats the eligibility as a list of questions and answers, each
      # accompanied by a slug for changing the answer. Suitable for playback to
      # the claimant for them to review on the check-your-answers page.
      #
      # Returns an array. Each element of this an array is an array of three
      # elements:
      # [0]: question text;
      # [1]: answer text;
      # [2]: slug for changing the answer.
      def eligibility_answers
        [].tap do |a|
          a << current_school
          a << nqt_in_academic_year_after_itt
          a << induction_completed
          a << employed_as_supply_teacher
          a << has_entire_term_contract if eligibility.employed_as_supply_teacher?
          a << employed_directly if eligibility.employed_as_supply_teacher?
          a << subject_to_formal_performance_action
          a << subject_to_disciplinary_action

          a << qualification
          a << itt_academic_year
          a << eligible_itt_subject
          a << eligible_degree_subject

          a << teaching_subject_now
        end.compact
      end

      private

      def has_entire_term_contract
        [
          t("additional_payments.forms.entire_term_contract.questions.has_entire_term_contract"),
          (eligibility.has_entire_term_contract? ? "Yes" : "No"),
          "entire-term-contract"
        ]
      end

      def current_school
        [
          t("additional_payments.forms.current_school.questions.current_school_search"),
          eligibility.current_school_name,
          (eligibility.school_somewhere_else == false) ? "correct-school" : "current-school"
        ]
      end

      def nqt_in_academic_year_after_itt
        [
          t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"),
          (eligibility.nqt_in_academic_year_after_itt? ? "Yes" : "No"),
          "nqt-in-academic-year-after-itt"
        ]
      end

      def induction_completed
        [
          t("additional_payments.questions.induction_completed.heading"),
          (eligibility.induction_completed? ? "Yes" : "No"),
          "induction-completed"
        ]
      end

      def employed_as_supply_teacher
        [
          t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"),
          (eligibility.employed_as_supply_teacher? ? "Yes" : "No"),
          "supply-teacher"
        ]
      end

      def employed_directly
        [
          t("additional_payments.forms.employed_directly.questions.employed_directly"),
          (eligibility.employed_directly? ? "Yes" : "No"),
          "employed-directly"
        ]
      end

      def subject_to_formal_performance_action
        [
          t("additional_payments.forms.poor_performance.questions.formal_performance_action"),
          (eligibility.subject_to_formal_performance_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end

      def subject_to_disciplinary_action
        [
          t("additional_payments.forms.poor_performance.questions.disciplinary_action"),
          (eligibility.subject_to_disciplinary_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end

      def qualification
        return if answers.qualifications_details_check && answers.early_career_payments_dqt_teacher_record&.route_into_teaching

        [
          t("additional_payments.forms.qualification.questions.which_route"),
          t("early_career_payments.forms.qualification.answers.#{answers.qualification}"),
          "qualification"
        ]
      end

      def eligible_itt_subject
        return if answers.qualifications_details_check && answers.early_career_payments_dqt_teacher_record&.eligible_itt_subject_for_claim

        [
          eligible_itt_subject_translation(
            shim.answers,
            subject_symbols
          ),
          text_for_subject_answer,
          "eligible-itt-subject"
        ]
      end

      def eligible_degree_subject
        return if !eligibility.respond_to?(:eligible_degree_subject) || !eligibility.eligible_degree_subject? || (answers.qualifications_details_check && answers.levelling_up_premium_payments_dqt_reacher_record&.eligible_degree_code?)

        [
          t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"),
          "Yes",
          "eligible-degree-subject"
        ]
      end

      def teaching_subject_now
        [
          t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now", eligible_itt_subject: eligibility.eligible_itt_subject),
          (eligibility.teaching_subject_now? ? "Yes" : "No"),
          "teaching-subject-now"
        ]
      end

      def itt_academic_year
        return if answers.qualifications_details_check && answers.early_career_payments_dqt_teacher_record&.itt_academic_year_for_claim

        [
          I18n.t("additional_payments.questions.itt_academic_year.qualification.#{answers.qualification}"),
          eligibility.itt_academic_year.to_s.gsub("/", " - "),
          "itt-year"
        ]
      end

      def text_for_subject_answer
        policy = eligibility.policy
        subjects = JourneySubjectEligibilityChecker.new(claim_year: Journeys.for_policy(policy).configuration.current_academic_year,
          itt_year: eligibility.itt_academic_year).current_and_future_subject_symbols(policy)

        if subjects.many?
          t("additional_payments.forms.eligible_itt_subject.answers.#{eligibility.eligible_itt_subject}")
        else
          subject_symbol = subjects.first
          (subject_symbol == eligibility.eligible_itt_subject.to_sym) ? "Yes" : "No"
        end
      end

      private

      def subject_symbols
        return [] if answers.itt_academic_year.blank?

        if shim.answers.nqt_in_academic_year_after_itt
          JourneySubjectEligibilityChecker.new(claim_year: answers.policy_year, itt_year: answers.itt_academic_year).current_and_future_subject_symbols(eligibility.policy)
        elsif answers.policy_year.in?(EligibilityCheckable::COMBINED_ECP_AND_LUP_POLICY_YEARS_BEFORE_FINAL_YEAR)
          # they get the standard, unchanging LUP subject set because they won't have qualified in time for ECP by 2022/2023
          # and they won't have given an ITT year
          JourneySubjectEligibilityChecker.fixed_lup_subject_symbols
        else
          []
        end.sort
      end

      def claim_submission_form
        @claim_submission_form ||= ClaimSubmissionForm.new(journey_session: shim)
      end

      def shim
        @shim ||= ClaimJourneySessionShim.new(
          journey_session: journey_session,
          current_claim: claim
        )
      end
    end
  end
end
