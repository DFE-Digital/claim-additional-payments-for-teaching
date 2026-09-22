module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class VerifyNationalInsuranceNumberForm < Form
      attribute :national_insurance_number_correct, :boolean
      attribute :national_insurance_number, :string

      validates :national_insurance_number_correct,
        inclusion: {
          in: [true, false],
          message: "Select yes if your National Insurance number matches the displayed value"
        }

      validates :national_insurance_number,
        national_insurance_number_format: {
          if: proc { |a| national_insurance_number_correct == false },
          message: "Enter your National Insurance number"
        }

      def save
        return false if invalid?

        journey_session
          .answers
          .update!(
            national_insurance_number_correct:,
            national_insurance_number:
          )

        true
      end
    end
  end
end
