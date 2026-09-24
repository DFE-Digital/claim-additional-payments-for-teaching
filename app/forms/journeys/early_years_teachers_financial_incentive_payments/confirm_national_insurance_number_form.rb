module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class ConfirmNationalInsuranceNumberForm < Form
      attribute :confirm_national_insurance_number, :boolean
      attribute :national_insurance_number, :string, strip_all_whitespace: true

      before_validation do
        if national_insurance_number.present?
          self.national_insurance_number = national_insurance_number.upcase
        end
      end

      validates(
        :confirm_national_insurance_number,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:blank)
        }
      )

      validates(
        :national_insurance_number,
        presence: {
          message: i18n_error_message(:national_insurance_number_format)
        },
        if: :national_insurance_number_entered?
      )

      validates(
        :national_insurance_number,
        national_insurance_number_format: {
          message: i18n_error_message(:national_insurance_number_format)
        },
        if: -> { national_insurance_number_entered? && national_insurance_number.present? }
      )

      def trs_national_insurance_number
        answers.trs_national_insurance_number
      end

      def save
        nino_was = answers.national_insurance_number

        return false if invalid?

        journey_session.answers.update!(
          confirm_national_insurance_number: confirm_national_insurance_number,
          national_insurance_number: confirmed_national_insurance_number
        )

        # If nino is changed fetch new data from hmrc
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

      private

      # The claimant only enters their own National Insurance number when they
      # tell us the one from their teaching record is wrong.
      def national_insurance_number_entered?
        confirm_national_insurance_number == false
      end

      def confirmed_national_insurance_number
        if confirm_national_insurance_number
          trs_national_insurance_number
        else
          national_insurance_number
        end
      end
    end
  end
end
