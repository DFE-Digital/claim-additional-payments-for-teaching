module AutomatedChecks
  module ClaimVerifiers
    module EarlyYearsTeachersFinancialIncentivePayments
      class Employment
        def initialize(claim:)
          @claim = claim
        end

        def perform
          Tasks::EarlyYearsTeachersFinancialIncentivePayments::EmploymentJob
            .perform_later(claim)
        end

        private

        attr_reader :claim
      end
    end
  end
end
