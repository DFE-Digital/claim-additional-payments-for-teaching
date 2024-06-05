# Temp class to allow working with the current_claims and the journey_session.
# As each form is updated to write to the journey_session rather than the
# current_claim we can remove the corresponding methods and update the answers
# hash to pull it's answer directly from the journey_session. When all answers
# in the answers hash have been updated to only refer to the journey_session
# this class can be removed.

module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimJourneySessionShim < ClaimJourneySessionShim
      def answers
        @answers ||= SessionAnswers.new(
          super.merge(
            {
              qts_award_year: qts_award_year,
              claim_school_id: journey_session.answers.claim_school_id,
              current_school_id: current_school_id,
              employment_status: journey_session.answers.employment_status,
              biology_taught: journey_session.answers.biology_taught,
              chemistry_taught: journey_session.answers.chemistry_taught,
              computing_taught: journey_session.answers.computing_taught,
              languages_taught: journey_session.answers.languages_taught,
              physics_taught: journey_session.answers.physics_taught,
              taught_eligible_subjects: journey_session.answers.taught_eligible_subjects,
              student_loan_repayment_amount: student_loan_repayment_amount,
              had_leadership_position: journey_session.answers.had_leadership_position,
              mostly_performed_leadership_duties: journey_session.answers.mostly_performed_leadership_duties,
              claim_school_somewhere_else: journey_session.answers.claim_school_somewhere_else
            }
          )
        )
      end

      private

      def qts_award_year
        journey_session.answers.qts_award_year || try_eligibility(:qts_award_year)
      end

      def current_school_id
        journey_session.answers.current_school_id || try_eligibility(:current_school_id)
      end

      def student_loan_repayment_amount
        journey_session.answers.student_loan_repayment_amount || try_eligibility(:student_loan_repayment_amount)
      end
    end
  end
end
