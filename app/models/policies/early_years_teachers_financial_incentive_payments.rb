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
      :other_reason_only_used_in_exceptional_circumstances
    ]

    def hidden?
      Rails.env.production? && !ENV["ENVIRONMENT_NAME"].start_with?("review")
    end

    def notify_reply_to_id
      # TODO find out what this needs to be
    end

    def auto_check_student_loan_plan_task?
      true
    end

    def decision_deadline_in_weeks
      10.weeks
    end
  end
end
