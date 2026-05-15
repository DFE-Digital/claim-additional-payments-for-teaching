module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class EligibilityAdminAnswersPresenter
      include Admin::PresenterMethods
      include ActionView::Helpers::NumberHelper

      attr_reader :eligibility

      def initialize(eligibility)
        @eligibility = eligibility
      end

      def answers
        [].tap do |a|
          a << ["Provider name", provider.name]
        end
      end

      def provider_details
        [
          ["Provider URN", provider.urn],
          ["Provider name", provider.name],
          ["Provider address", provider.address]
        ]
      end

      def policy_options_provided
        [
          [
            I18n.t("early_years_teachers_financial_incentive_payments.policy_short_name"),
            number_to_currency(eligibility.award_amount, precision: 0)
          ]
        ]
      end

      private

      def provider
        eligibility.eligible_eytfi_provider
      end
    end
  end
end
