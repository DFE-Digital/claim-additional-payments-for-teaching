module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class AdminTasksPresenter
      include Admin::PresenterMethods

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def student_loan_plan
        [
          ["Student loan plan", claim.student_loan_plan&.humanize]
        ]
      end
    end
  end
end
