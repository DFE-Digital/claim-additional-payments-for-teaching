module Journeys
  module TeacherStudentLoanReimbursement
    class SelectClaimSchoolForm < Form
      attribute :change_school, :boolean
      attribute :claim_school_id, :string

      delegate :address, :name, to: :claim_school, prefix: true, allow_nil: true
      delegate :claim_school_somewhere_else?, to: :answers

      def save
        return false unless valid?

        if change_school?
          journey_session.answers.assign_attributes(
            claim_school_id: nil,
            claim_school_somewhere_else: true,
            taught_eligible_subjects: nil,
            biology_taught: nil,
            physics_taught: nil,
            chemistry_taught: nil,
            computing_taught: nil,
            languages_taught: nil,
            employment_status: nil,
            current_school_id: nil
          )
        else
          journey_session.answers.assign_attributes(
            claim_school_id: claim_school_id,
            claim_school_somewhere_else: false
          )
        end

        journey_session.save!

        # FIXME RL: Remove this once the current school forms write their
        # answers to the session
        claim.eligibility.assign_attributes(current_school_id: nil)
        # FIXME RL: Remove this once the current school forms write their
        # answers to the session
        claim.eligibility.save!

        true
      end

      def claim_school_id
        @claim_school_id ||= permitted_params.fetch(:claim_school_id, claim_school&.id)
      end

      private

      def claim_school
        @claim_school ||= journey_session.tps_school_for_student_loan_in_previous_financial_year || answers.claim_school
      end

      def change_school?
        change_school || claim_school_id.nil? || claim_school_id == "somewhere_else"
      end
    end
  end
end
