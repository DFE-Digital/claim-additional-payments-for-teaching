module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimJourneySessionShim < ClaimJourneySessionShim
      def answers
        OpenStruct.new(
          attributes: super.merge(
            {
              qts_award_year: qts_award_year,
              claim_school_id: claim_school_id,
              current_school_id: current_school_id,
              employment_status: employment_status,
              biology_taught: biology_taught,
              chemistry_taught: chemistry_taught,
              computing_taught: computing_taught,
              languages_taught: languages_taught,
              physics_taught: physics_taught,
              taught_eligible_subjects: taught_eligible_subjects,
              student_loan_repayment_amount: student_loan_repayment_amount,
              had_leadership_position: had_leadership_position,
              mostly_performed_leadership_duties: mostly_performed_leadership_duties,
              claim_school_somewhere_else: claim_school_somewhere_else
            }
          )
        )
      end

      private

      def qts_award_year
        journey_session.answers.qts_award_year || try_eligibility(:qts_award_year)
      end

      def claim_school_id
        journey_session.answers.claim_school_id || try_eligibility(:claim_school_id)
      end

      def current_school_id
        journey_session.answers.current_school_id || try_eligibility(:current_school_id)
      end

      def employment_status
        journey_session.answers.employment_status || try_eligibility(:employment_status)
      end

      def biology_taught
        journey_session.answers.biology_taught || try_eligibility(:biology_taught)
      end

      def chemistry_taught
        journey_session.answers.chemistry_taught || try_eligibility(:chemistry_taught)
      end

      def computing_taught
        journey_session.answers.computing_taught || try_eligibility(:computing_taught)
      end

      def languages_taught
        journey_session.answers.languages_taught || try_eligibility(:languages_taught)
      end

      def physics_taught
        journey_session.answers.physics_taught || try_eligibility(:physics_taught)
      end

      def taught_eligible_subjects
        journey_session.answers.taught_eligible_subjects || try_eligibility(:taught_eligible_subjects)
      end

      def student_loan_repayment_amount
        journey_session.answers.student_loan_repayment_amount || try_eligibility(:student_loan_repayment_amount)
      end

      def had_leadership_position
        journey_session.answers.had_leadership_position || try_eligibility(:had_leadership_position)
      end

      def mostly_performed_leadership_duties
        journey_session.answers.mostly_performed_leadership_duties || try_eligibility(:mostly_performed_leadership_duties)
      end

      def claim_school_somewhere_else
        journey_session.answers.claim_school_somewhere_else || try_eligibility(:claim_school_somewhere_else)
      end
    end
  end
end
