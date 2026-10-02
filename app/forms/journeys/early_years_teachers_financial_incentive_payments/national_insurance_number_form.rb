module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class NationalInsuranceNumberForm < ::NationalInsuranceNumberForm
      def save
        nino_was = answers.national_insurance_number

        return false unless super

        if nino_was != answers.national_insurance_number
          journey_session.answers.update!(
            hmrc_response_status: nil,
            hmrc_response_body: nil
          )

          ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob.perform_later(
            journey_session
          )
        end

        true
      end
    end
  end
end
