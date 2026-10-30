module AutomatedChecks
  module ClaimVerifiers
    module EarlyYearsTeachersFinancialIncentivePayments
      class Employment
        def initialize(claim:)
          @claim = claim
          @eligibility = claim.eligibility
        end

        def perform
          return if claim.tasks.employment.exists?

          ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob.perform_now(claim)

          task = claim.tasks.employment.new

          if employment_check.passed?
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

        private

        attr_reader :claim, :eligibility

        def employment_check
          Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck.new(
            setting: eligibility.nursery,
            hmrc_response_status: eligibility.hmrc_response_status,
            hmrc_response_body: eligibility.hmrc_response_body
          )
        end
      end
    end
  end
end
