module Journeys
  module TeacherStudentLoanReimbursement
    class NationalInsuranceNumberForm < ::NationalInsuranceNumberForm
      def save
        previous_nino = answers.national_insurance_number

        return false unless super

        # Student loan details are looked up by NINO, so recheck them if the
        # claimant has changed their NINO
        if answers.national_insurance_number != previous_nino
          answers.update!(student_loan_amount_seen: false)
          AnswersStudentLoansDetailsUpdater.call(journey_session)
        end

        true
      end
    end
  end
end
