module Journeys
  module TeacherStudentLoanReimbursement
    class EligibilityChecker
      attr_reader :journey_session

      delegate_missing_to :checker

      def initialize(journey_session:)
        @journey_session = journey_session
      end

      # FIXME this could be shared with the additional payments eligibility
      # checker, just make a journey eligibility checker
      private

      def checker
        @checker ||= Policies::StudentLoans::EligibilityChecker.new(
          journey_session.answers
        )
      end
    end
  end
end
