module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class NationalInsuranceNumberForm < ::NationalInsuranceNumberForm
      def save
        return false unless super

        ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob.perform_later(
          journey_session
        )

        true
      end
    end
  end
end
