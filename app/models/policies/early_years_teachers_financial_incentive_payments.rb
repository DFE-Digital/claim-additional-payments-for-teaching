module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    include BasePolicy
    extend self

    VERIFIERS = [
      AutomatedChecks::ClaimVerifiers::OneLoginIdentity,
      AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
      AutomatedChecks::ClaimVerifiers::EyQualificationCheck
    ]

    ADMIN_DECISION_REJECTED_REASONS = [
      :no_response,
      :claimant_withdrew_application,
      :cant_verify_claimant_is_employed_at_setting,
      :duplicate_claim,
      :other_reason_only_used_in_exceptional_circumstances
    ]

    def hidden?
      Rails.env.production? && !ENV["ENVIRONMENT_NAME"].start_with?("review")
    end

    def notify_reply_to_id
      "f7ad7769-b521-4b30-bd60-9779cfe12c63".freeze
    end

    def auto_check_student_loan_plan_task?
      true
    end

    def decision_deadline_in_weeks
      10.weeks
    end
  end
end
