# This class lets us use English definitions in the
# policy's `claim_attributes` and `eligibility_attributes` hashes.
# Define a new private method here to make it available as a value
# in the attributes hash.
module Policies
  module DataRetention
    class EvaluationContext
      def initialize(claim)
        @claim = claim
      end

      def condition_met?(condition)
        send(condition)
      end

      # TODO rename previous to prior as may be a couple of terms ago
      def inactive_claim_submitted_in_previous_academic_term?
        inactive? && submitted_in_previous_academic_term?
      end

      def submitted_in_previous_academic_term?
        Date.today > @claim.academic_year.next.start_of_autumn_term
      end

      def retained
        false
      end

      def inactive?
        old_rejected_claim? || old_paid_claim?
      end

      def old_rejected_claim?
        claim.rejected? && claim.latest_decision.created_at < start_of_current_academic_year.beginning_of_day
      end

      def old_paid_claim?
        claim.paid? && claim.most_recent_scheduled_payment_date < start_of_current_academic_year.beginning_of_day
      end

      private

      attr_reader :claim

      def start_of_current_academic_year
        AcademicYear.current.start_of_autumn_term
      end
    end
  end
end
