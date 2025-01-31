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
          a << has_entire_term_contract if journey_session.answers.employed_as_supply_teacher?
          a << employed_directly if journey_session.answers.employed_as_supply_teacher?
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
          (answers.has_entire_term_contract? ? "Yes" : "No"),
          "entire-term-contract"
        ]
      end

      def current_school
        [
          t("additional_payments.forms.current_school.questions.current_school_search"),
          journey_session.answers.current_school.name,
          (journey_session.answers.school_somewhere_else == false) ? "correct-school" : "current-school"
        ]
      end

      def nqt_in_academic_year_after_itt
        [
          t("additional_payments.questions.nqt_in_academic_year_after_itt.heading"),
          (journey_session.answers.nqt_in_academic_year_after_itt? ? "Yes" : "No"),
          "nqt-in-academic-year-after-itt"
        ]
      end

      def induction_completed
        [
          t("additional_payments.questions.induction_completed.heading"),
          (journey_session.answers.induction_completed? ? "Yes" : "No"),
          "induction-completed"
        ]
      end

      def employed_as_supply_teacher
        [
          t("additional_payments.forms.supply_teacher.questions.employed_as_supply_teacher"),
          (journey_session.answers.employed_as_supply_teacher? ? "Yes" : "No"),
          "supply-teacher"
        ]
      end

      def employed_directly
        [
          t("additional_payments.forms.employed_directly.questions.employed_directly"),
          (answers.employed_directly? ? "Yes" : "No"),
          "employed-directly"
        ]
      end

      def subject_to_formal_performance_action
        [
          t("additional_payments.forms.poor_performance.questions.performance.question"),
          (journey_session.answers.subject_to_formal_performance_action? ? "Yes" : "No"),
          "poor-performance"
        ]
      end

      def subject_to_disciplinary_action
        [
          t("additional_payments.forms.poor_performance.questions.disciplinary.question"),
          (journey_session.answers.subject_to_disciplinary_action? ? "Yes" : "No"),
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
            answers,
            subject_symbols
          ),
          text_for_subject_answer,
          "eligible-itt-subject"
        ]
      end

      def eligible_degree_subject
        return if !answers.eligible_degree_subject? || (answers.qualifications_details_check && answers.targeted_retention_incentive_payments_dqt_reacher_record&.eligible_degree_code?)

        [
          t("additional_payments.forms.eligible_degree_subject.questions.eligible_degree_subject"),
          "Yes",
          "eligible-degree-subject"
        ]
      end

      def teaching_subject_now
        [
          t("additional_payments.forms.teaching_subject_now.questions.teaching_subject_now", eligible_itt_subject: journey_session.answers.eligible_itt_subject),
          (journey_session.answers.teaching_subject_now? ? "Yes" : "No"),
          "teaching-subject-now"
        ]
      end

      def itt_academic_year
        return if answers.qualifications_details_check && answers.early_career_payments_dqt_teacher_record&.itt_academic_year_for_claim

        [
          I18n.t("additional_payments.questions.itt_academic_year.qualification.#{answers.qualification}"),
          journey_session.answers.itt_academic_year.to_s.gsub("/", " - "),
          "itt-year"
        ]
      end

      def text_for_subject_answer
        policy = eligibility.policy

        subjects = policy.current_and_future_subject_symbols(
          claim_year: Journeys.for_policy(policy).configuration.current_academic_year,
          itt_year: journey_session.answers.itt_academic_year
        )

        if subjects.many?
          t("additional_payments.forms.eligible_itt_subject.answers.#{journey_session.answers.eligible_itt_subject}")
        else
          subject_symbol = subjects.first
          (subject_symbol == eligibility.eligible_itt_subject.to_sym) ? "Yes" : "No"
        end
      end

      private

      def subject_symbols
        @subject_symbols ||= answers.policy.subject_symbols(
          claim_year: answers.policy_year,
          itt_year: answers.itt_academic_year
        )
      end

      def claim_submission_form
        @claim_submission_form ||= ClaimSubmissionForm.new(journey_session: journey_session)
      end
    end
  end
end
