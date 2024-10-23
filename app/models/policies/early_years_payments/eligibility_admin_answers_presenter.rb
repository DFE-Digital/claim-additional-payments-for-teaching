module Policies
  module EarlyYearsPayments
    class EligibilityAdminAnswersPresenter
      include Admin::PresenterMethods
      include ActionView::Helpers::NumberHelper

      attr_reader :eligibility

      def initialize(eligibility)
        @eligibility = eligibility
      end

      def answers
        []
      end
    end
  end
end
