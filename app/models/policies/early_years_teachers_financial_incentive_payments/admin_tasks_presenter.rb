module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class AdminTasksPresenter
      include Admin::PresenterMethods

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end
    end
  end
end
