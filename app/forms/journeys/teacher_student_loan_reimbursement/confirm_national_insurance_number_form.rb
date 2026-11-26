module Journeys
  module TeacherStudentLoanReimbursement
    class ConfirmNationalInsuranceNumberForm < Form
      attribute :confirm_national_insurance_number, :boolean
      attribute(
        :national_insurance_number,
        :string,
        strip_all_whitespace: true
      )

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
        if: -> {
          national_insurance_number_entered? &&
            national_insurance_number.present?
        }
      )

      def trs_national_insurance_number
        answers.teacher_auth_national_insurance_number
      end

      def save
        return false if invalid?

        previous_nino = answers.national_insurance_number

        journey_session.answers.update!(
          confirm_national_insurance_number: confirm_national_insurance_number,
          national_insurance_number: confirmed_national_insurance_number
        )

        # Student loan details are looked up by NINO, so recheck them if the
        # claimant has changed their NINO
        if answers.national_insurance_number != previous_nino
          answers.update!(student_loan_amount_seen: false)
          AnswersStudentLoansDetailsUpdater.call(journey_session)
        end

        true
      end

      private

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
