module Policies
  module EarlyYearsPayments
    class AdminTasksPresenter
      include Admin::PresenterMethods

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def employment
        [
          ["Current employment", claim.eligibility.eligible_ey_provider.nursery_name],
          ["Start date", l(claim.eligibility.start_date)]
        ]
      end
    end
  end
end
