module Journeys
  module TeacherStudentLoanReimbursement
    class SelectClaimSchoolForm < Form
      attribute :change_school, :boolean
      attribute :claim_school_id, :string

      delegate :address, :name, to: :claim_school, prefix: true, allow_nil: true
      delegate :eligibility, to: :claim
      delegate :claim_school_somewhere_else?, to: :eligibility

      def save
        claim.update(eligibility_attributes:)
        claim.reset_eligibility_dependent_answers(["claim_school_id"])
        true
      end

      def claim_school_id
        @claim_school_id ||= permitted_params.fetch(:claim_school_id, claim_school&.id)
      end

      private

      def claim_school
        @claim_school ||= claim.tps_school_for_student_loan_in_previous_financial_year || claim.eligibility.claim_school
      end

      def change_school?
        change_school || claim_school_id.nil? || claim_school_id == "somewhere_else"
      end

      def eligibility_attributes
        return {claim_school_id: nil, claim_school_somewhere_else: true} if change_school?

        {claim_school_id:, claim_school_somewhere_else: false}
      end
    end
  end
end
