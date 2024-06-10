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
              nqt_in_academic_year_after_itt: nqt_in_academic_year_after_itt,
              employed_as_supply_teacher: employed_as_supply_teacher,
              qualification: journey_session.answers.qualification,
              has_entire_term_contract: has_entire_term_contract,
              employed_directly: employed_directly,
              subject_to_disciplinary_action: subject_to_disciplinary_action,
              subject_to_formal_performance_action: subject_to_formal_performance_action,
              eligible_itt_subject: eligible_itt_subject,
              eligible_degree_subject: journey_session.answers.eligible_degree_subject,
              teaching_subject_now: teaching_subject_now,
              itt_academic_year: journey_session.answers.itt_academic_year,
              current_school_id: current_school_id,
              induction_completed: induction_completed,
              school_somewhere_else: journey_session.answers.school_somewhere_else
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

      # FIXME RL: This will be removed once we have migrated the
      # eligible_itt_subject form. This is required as
      # `EarlyCareerPayments::DqtRecord` and
      # `LevellingUpPremiumPayments::DqtRecord` can return different values for
      # eligible_itt_subject, however the `answers` only store one
      # `eligible_itt_subject`. The slug sequence specificly checks if the
      # claim is lup ineligible, which if the answers eligible_itt_subject is
      # set to the value from the ecp dqt record can return false (ie
      # ecp_dqt_record returns 'none_of_the_above' and lup_dqt_record returns
      # 'mathematics'). However the `eligible_itt_subject` form writes the
      # answer selected by the teacher to both claims, implying that the
      # eligible_itt_subject should be the same for both policies, so either
      # there is an issue with how the dqt_record differ in calculating the
      # eligible_itt_subject or the `eligible_itt_subject` form is wrong in
      # writing the same eligible_itt_subject to both claims.
      # If the former, wen we update the `eligible_itt_subject` form, we'll
      # also want to update the qualification details from to have logic
      # similar to the below. If the later, then we'll need to change answers
      # to have an `ecp_eligible_itt_subject` and `lup_eligible_itt_subject`,
      # and update the `eligible_itt_subject` form to write the same answer to
      # both.
      def eligible_itt_subject
        answer_from_session = journey_session.answers.eligible_itt_subject
        return answer_from_session if answer_from_session.present?
        subjects_from_claim = current_claim.claims.map(&:eligibility).map(&:eligible_itt_subject).compact.map(&:to_sym)

        return nil if subjects_from_claim.empty?

        not_none_of_the_above = subjects_from_claim.reject { |subject| subject == :none_of_the_above }

        if not_none_of_the_above.any?
          not_none_of_the_above.first
        else
          :none_of_the_above
        end
      end

      def teaching_subject_now
        journey_session.answers.teaching_subject_now || try_eligibility(:teaching_subject_now)
      end

      def current_school_id
        journey_session.answers.current_school_id || try_eligibility(:current_school_id)
      end

      def induction_completed
        journey_session.answers.induction_completed || try_eligibility(:induction_completed)
      end
    end
  end
end
