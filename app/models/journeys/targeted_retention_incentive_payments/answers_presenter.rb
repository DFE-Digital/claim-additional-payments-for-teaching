module Journeys
  module TargetedRetentionIncentivePayments
    class AnswersPresenter < BaseAnswersPresenter
      def eligibility_answers
        [].tap do |a|
          a << current_school
          a << nqt_in_academic_year_after_itt
          #a << induction_completed
          a << employed_as_supply_teacher
          #a << has_entire_term_contract if journey_session.answers.employed_as_supply_teacher?
          #a << employed_directly if journey_session.answers.employed_as_supply_teacher?
          a << subject_to_formal_performance_action
          a << subject_to_disciplinary_action

          a << qualification
          a << itt_academic_year
          a << eligible_itt_subject
          #a << eligible_degree_subject

          a << teaching_subject_now
        end.compact
      end

      private

      def current_school
        [
          t("current_school.questions.current_school_search"),
          answers.current_school.name,
          "correct-school"
          #(answers.school_somewhere_else == false) ? "correct-school" : "current-school"
        ]
      end

      def nqt_in_academic_year_after_itt
        [
          t("nqt_in_academic_year_after_itt.question"),
          t("nqt_in_academic_year_after_itt.options.#{answers.nqt_in_academic_year_after_itt}"),
          "nqt-in-academic-year-after-itt"
        ]
      end

      def employed_as_supply_teacher
        [
          t("supply_teacher.question"),
          t("supply_teacher.options.#{answers.employed_as_supply_teacher}"),
          "supply-teacher"
        ]
      end

      def subject_to_formal_performance_action
        [
          t("poor_performance.questions.performance.question"),
          answers.subject_to_formal_performance_action ? "Yes" : "No",
          "poor-performance"
        ]
      end

      def subject_to_disciplinary_action
        [
          t("poor_performance.questions.disciplinary.question"),
          answers.subject_to_disciplinary_action ? "Yes" : "No",
          "poor-performance"
        ]
      end

      def qualification
        [
          t("qualification.question"),
          t("qualification.options.#{answers.qualification}"),
          "qualification"
        ]
      end

      def itt_academic_year
        [
          t("itt_academic_year.question.#{answers.qualification}"),
          answers.itt_academic_year.to_s(:long),
          "itt_academic_year"
        ]
      end

      def eligible_itt_subject
        label = if answers.trainee_teacher?
          t("eligible_itt_subject.question.trainee_teacher")
        else
          t("eligible_itt_subject.question.qualified.#{answers.qualification}")
        end

        [
          label,
          t("eligible_itt_subject.options.#{answers.eligible_itt_subject}"),
          "eligible-itt-subject"
        ]
      end

      #def eligible_degree_subject
      #  [
      #    t("eligible_degree_subject.question"),
      #    answers.eligible_degree_subject ? "Yes" : "No",
      #    "eligible-degree-subject"
      #  ]
      #end

      def teaching_subject_now
        [
          t("teaching_subject_now.question"),
          t("teaching_subject_now.options.#{answers.teaching_subject_now}"),
          "teaching-subject-now"
        ]
      end

      def t(key)
        I18n.t(
          [
            "targeted_retention_incentive_payments",
            "forms",
            key
          ].join(".")
        )
      end
    end
  end
end
