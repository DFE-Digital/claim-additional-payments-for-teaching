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

          task = claim.tasks.employment.new

          if employment_check.passed?
            task.passed = true
            task.manual = false
          else
            task.passed = nil
            task.manual = true
            task.reason = "incomplete" # set this so the task presenter shows "Incomplete"
          end

          ApplicationRecord.transaction do
            task.save!(context: :claim_verifier)

            claim.notes.create!(
              label: task.name,
              body: [
                "HMRC API STATUS: #{hmrc_response_message}",
                "HMRC EMPLOYMENTS: #{hmrc_employer_names}"
              ].join("\n")
            )
          end

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

        def hmrc_response_message
          case eligibility.hmrc_response_status
          when 200...299
            "Success"
          when 404
            "Claimant not found"
          else
            "Error"
          end
        end

        def hmrc_employer_names
          employment_check.employer_names
        end
      end
    end
  end
end
