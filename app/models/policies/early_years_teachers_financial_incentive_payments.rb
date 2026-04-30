module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    include BasePolicy
    extend self

    VERIFIERS = []

    ADMIN_DECISION_REJECTED_REASONS = []

    def hidden?
      true
    end
  end
end
