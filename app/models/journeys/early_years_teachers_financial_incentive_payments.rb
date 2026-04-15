module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    extend Base
    extend self

    POLICIES = [Policies::EarlyYearsTeachersFinancialIncentivePayments]
    FORMS = [
      SignInForm
    ]

    def available?
      FeatureFlag.enabled?(:eytfi_journey)
    end
  end
end
