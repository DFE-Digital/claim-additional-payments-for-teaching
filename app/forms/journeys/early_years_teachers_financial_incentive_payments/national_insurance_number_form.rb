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

          # If we're by passing hmrc don't run the job. As we're setting
          # hmrc_api_job_completed to false we'll rerender the hmrc employment
          # check form.
          unless Rails.configuration.x.hmrc_employment_check_bypass
            ::EarlyYearsTeachersFinancialIncentivePayments::HmrcEmploymentCheckJob.perform_later(
              journey_session
            )
          end
        end

        true
      end
    end
  end
end
