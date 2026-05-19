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

      def qualifications
        [
          [
            "Qualification",
            "Qualification verified as #{claim.eligibility.ey_qualification} on #{l(claim.eligibility.trs_data_fetched_at.to_date)}"
          ]
        ]
      end
    end
  end
end
