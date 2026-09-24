module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class NationalInsuranceNumberForm < ::NationalInsuranceNumberForm
      def save
        nino_was = answers.national_insurance_number

        return false unless super

        if nino_was != answers.national_insurance_number
          journey_session.answers.update!(
            hmrc_employment_check_passed: nil,
            hmrc_api_job_completed: false,
            hmrc_employment_history: nil,
            hmrc_employent_api_call_status: nil
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
