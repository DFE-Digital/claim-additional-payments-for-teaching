# Temp class to allow working with the current_claims and the journey_session.
# As each form is updated to write to the journey_session rather than the
# current_claim we can remove the corresponding methods and update the answers
# hash to pull it's answer directly from the journey_session. When all answers
# in the answers hash have been updated to only refer to the journey_session
# this class can be removed.

module Journeys
  module AdditionalPaymentsForTeaching
    class ClaimJourneySessionShim < ClaimJourneySessionShim
      def answers
        @answers ||= SessionAnswers.new(
          super.merge(
            {
              selected_policy: journey_session.answers.selected_policy,
              nqt_in_academic_year_after_itt: journey_session.answers.nqt_in_academic_year_after_itt,
              employed_as_supply_teacher: employed_as_supply_teacher,
              qualification: journey_session.answers.qualification,
              has_entire_term_contract: journey_session.answers.has_entire_term_contract,
              employed_directly: journey_session.answers.employed_directly,
              subject_to_disciplinary_action: subject_to_disciplinary_action,
              subject_to_formal_performance_action: subject_to_formal_performance_action,
              eligible_itt_subject: journey_session.answers.eligible_itt_subject,
              eligible_degree_subject: journey_session.answers.eligible_degree_subject,
              teaching_subject_now: journey_session.answers.teaching_subject_now,
              itt_academic_year: journey_session.answers.itt_academic_year,
              current_school_id: journey_session.answers.current_school_id,
              induction_completed: journey_session.answers.induction_completed,
              school_somewhere_else: journey_session.answers.school_somewhere_else
            }
          )
        )
      end

      private

      def employed_as_supply_teacher
        journey_session.answers.employed_as_supply_teacher
      end

      def subject_to_disciplinary_action
        journey_session.answers.subject_to_disciplinary_action || try_eligibility(:subject_to_disciplinary_action)
      end

      def subject_to_formal_performance_action
        journey_session.answers.subject_to_formal_performance_action || try_eligibility(:subject_to_formal_performance_action)
      end
    end
  end
end
