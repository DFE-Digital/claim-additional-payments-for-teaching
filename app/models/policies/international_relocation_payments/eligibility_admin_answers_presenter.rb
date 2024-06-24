module Policies
  module InternationalRelocationPayments
    class EligibilityAdminAnswersPresenter
      include Admin::PresenterMethods

      attr_reader :eligibility

      def initialize(eligibility)
        @eligibility = eligibility
      end

      def answers
        [].tap do |a|
          a << current_school
        end
      end

      private

      def current_school
        [
          translate("admin.current_school"),
          eligibility.current_school.present? ? display_school(eligibility.current_school) : "No"
        ]
      end
    end
  end
end
