module Tasks
  module EarlyYearsTeachersFinancialIncentivePayments
    class EmploymentJob < ApplicationJob
      def perform(claim)
        claim = claim
        eligibility = claim.eligibility

        return if claim.tasks.employment.exists?

        ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob
          .perform_now(claim)

        task = claim.tasks.employment.new

        employment_check = Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.new(
          setting: eligibility.nursery,
          hmrc_response_status: eligibility.hmrc_response_status,
          hmrc_response_body: eligibility.hmrc_response_body
        )

        result = employment_check.result

        task.data = {
          check: result.check,
          passed: result.passed?,
          failure_reason: result.failure_reason
        }

        if result.passed?
          task.passed = true
          task.manual = false
        else
          task.passed = nil
          task.manual = true
          task.reason = "incomplete" # set this so the task presenter shows "Incomplete"
        end

        task.save!(context: :claim_verifier)

        task
      end
    end
  end
end
