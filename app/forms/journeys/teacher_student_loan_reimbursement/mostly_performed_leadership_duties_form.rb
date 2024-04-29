module Journeys
  module TeacherStudentLoanReimbursement
    class MostlyPerformedLeadershipDutiesForm < Form
      attribute :mostly_performed_leadership_duties, :boolean

      validates :mostly_performed_leadership_duties,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("inclusion") }
        }

      def save
        return false unless valid?
        claim.update!(
          eligibility_attributes: {
            mostly_performed_leadership_duties: mostly_performed_leadership_duties
          }
        )
      end
    end
  end
end
