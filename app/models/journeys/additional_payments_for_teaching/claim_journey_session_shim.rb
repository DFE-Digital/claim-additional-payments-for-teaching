module Journeys
  module AdditionalPaymentsForTeaching
    class ClaimJourneySessionShim < ClaimJourneySessionShim
      def answers
        # NOTE RL: Call this out in commit message
        OpenStruct.new(
          attributes: super.merge(
            {
              nqt_in_academic_year_after_itt: nqt_in_academic_year_after_itt,
              employed_as_supply_teacher: employed_as_supply_teacher,
              qualification: qualification,
              has_entire_term_contract: has_entire_term_contract,
              employed_directly: employed_directly,
              subject_to_disciplinary_action: subject_to_disciplinary_action,
              subject_to_formal_performance_action: subject_to_formal_performance_action,
              eligible_itt_subject: eligible_itt_subject,
              eligible_degree_subject: eligible_degree_subject,
              teaching_subject_now: teaching_subject_now,
              itt_academic_year: itt_academic_year,
              current_school_id: current_school_id,
              induction_completed: induction_completed,
              school_somewhere_else: school_somewhere_else
            }
          )
        )
      end

      private

      def nqt_in_academic_year_after_itt
        journey_session.answers.nqt_in_academic_year_after_itt || try_eligibility(:nqt_in_academic_year_after_itt)
      end

      def employed_as_supply_teacher
        journey_session.answers.employed_as_supply_teacher || try_eligibility(:employed_as_supply_teacher)
      end

      def qualification
        journey_session.answers.qualification || try_eligibility(:qualification)
      end

      def has_entire_term_contract
        journey_session.answers.has_entire_term_contract || try_eligibility(:has_entire_term_contract)
      end

      def employed_directly
        journey_session.answers.employed_directly || try_eligibility(:employed_directly)
      end

      def subject_to_disciplinary_action
        journey_session.answers.subject_to_disciplinary_action || try_eligibility(:subject_to_disciplinary_action)
      end

      def subject_to_formal_performance_action
        journey_session.answers.subject_to_formal_performance_action || try_eligibility(:subject_to_formal_performance_action)
      end

      def eligible_itt_subject
        journey_session.answers.eligible_itt_subject || try_eligibility(:eligible_itt_subject)
      end

      def eligible_degree_subject
        journey_session.answers.eligible_degree_subject || try_eligibility(:eligible_degree_subject)
      end

      def teaching_subject_now
        journey_session.answers.teaching_subject_now || try_eligibility(:teaching_subject_now)
      end

      def itt_academic_year
        journey_session.answers.itt_academic_year || try_eligibility(:itt_academic_year)
      end

      def current_school_id
        journey_session.answers.current_school_id || try_eligibility(:current_school_id)
      end

      def induction_completed
        journey_session.answers.induction_completed || try_eligibility(:induction_completed)
      end

      def school_somewhere_else
        journey_session.answers.school_somewhere_else || try_eligibility(:school_somewhere_else)
      end
    end
  end
end
