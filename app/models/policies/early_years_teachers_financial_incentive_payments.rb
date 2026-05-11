module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    include BasePolicy
    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::OneLoginIdentity
    ]

    ADMIN_DECISION_REJECTED_REASONS = [
      :other_reason_only_used_in_exceptional_circumstances
    ]

    def hidden?
      Rails.env.production? && !ENV["ENVIRONMENT_NAME"].start_with?("review")
    end

    def notify_reply_to_id
      # TODO find out what this needs to be
    end
  end
end
